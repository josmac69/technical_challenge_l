# Data Architecture Challenge

## Task

We are managing parking lots that a client can check with a mobile app. An app can tell the drive if a parking is full or not. On entering/leaving the parking a client can scan QR/NFC code on entrance machines and the cost must be automatically charged when leaving parking. We are interested in monitoring when the parking is full or empty to modify prices accordingly. We also would like to create a predictive model that learns when a client is going to the parking to send him a push message informing how many places are left or if the parking is full.

1. What tracking events would you propose? What data model for event analysis? What technologies?
2. How would you design the Backend system? What data model for the Operational system? What technologies?
3. Explain how to combine the operational architecture with the analytical one?
4. Could you propose a process to manage the development lifecycle? And the test and deployment automation?

## Solution

The whole task would require further discussions to understand better all the details.
For example what type of parking lot are we actually managing? General public one or lot by some supermarket? Based on this we can expect different usage patterns and different seasonality of data.

But since this is a technical challenge I will list my assumptions and provide solution based on them.

The whole process of designing the solution is based on the pragmatic principle - [Make it Work, Make It Right, Make It Fast](https://wiki.c2.com/?MakeItWorkMakeItRightMakeItFast)


### Data model
Data gathered by the app are very simple and relational by design.
We shall use transactional database with strong consistency to avoid over booking of parking lots and problems with financial transactions.

#### User account master record
Overview:
* Holds information about user account.
* Only one record per user_id exists.
* Master record will be updated during financial transactions and manual user account updates.
* Table will be indexed by user_id, email, phone and user_name. Other indexes would be added based on usage.
* Table will most likely not be partitioned.
* Record will be locked during update.

Structure:
* `user_id`: integer automatically increased (serial) unique user identifier
* `user_name`: user name - required
* `email`: user main email address - required
* `email_verified`: flag indicating if email address is verified
* `phone`: user main phone number - required, can be read from mobile phone where app runs, can be used for SMS notifications
* `payment_details_key`: text value - key to payment details record in the third party system
* `currency`: currency of the account
* `account_balance`: current account balance
* `account_blocked`: flag indicating if account is blocked
* `account_blocked_reason`: reason why account is blocked
* `account_blocked_timestamp`: timestamp when account was blocked
* `created_at`: timestamp when account was created
* `created_by`: ID of the user / system who created the account
* `updated_at`: timestamp when account was updated
* `updated_by`: ID of the user / system who updated the account
* `metadata`: JSON record with additional data about user account

Notes:
* Payment details are stored in the third party system and are referenced by key. This way we avoid storing sensitive data in our system.
* Details are not discussed in this document. Since I presume this part would require security and privacy audit which is out of scope of this document.

##### User account audit transactions:
Overview:
* History of changes on user account. For analytical purposes.
* Data are only appended to the table, no updates or deletes are allowed. So no locking is required.
* Table will be indexed by user_id, timestamp and event_type. Other indexes would be added based on usage.
* Table will most likely be partitioned by date (timestamp rounded to full date).

Structure:
* `audit_id`: integer automatically increased (serial) unique audit transaction identifier
* `user_id`: integer user identifier
* `event_timestamp`: timestamp of the event
* `event_type`: type of the event
* `metadata`: JSON record describing data changed in the event

Audit events:
* `account_created`: account created, metadata contain all user data
* `email_verified`: email address verified - set email_verified flag to true in user master record
* `account_updated`: account updated, metadata contain changes
* `account_deleted`: account deleted, metadata contain reason
  * user shall receive confirmation about deletion by email or pusher notification
  * user account can be deleted deleted for example in case of too high debt or on request for example when user dies
  * if there are some money on the account, we shall send them back to user
* `account_blocked`: account blocked by us, metadata contain reason
  * account can be blocked by us for example in case of too high debt
  * user must be informed about this by email or pusher notification
* `account_unblocked`: account unblocked by us (timestamp, user ID, metadata)
  * when problem is solved and we unblock account
  * user must be informed about this by email or pusher notification
* `availability_check`: user checks availability of parking lot
  * this event will be triggered by user in mobile app
  * this event will be used for analytical purposes
  * this event will be used for predictive model
    * the event will help us understand for example how long before arriving at the parking lot the user usually checks if it is free
    * by amount of checks by all users in the current period of time we can predict availability of parking spaces in the near future
    * we can also inform users about frequency of checks from other users
* ? `booking`: for the future versions - user books parking space on parking lot
  * this event will be triggered by user in mobile app
  * this event will be used for analytical purposes
  * this event will be used for predictive model
    * the event will help us understand for example how long before arriving at the parking lot the user usually books it
    * by amount of bookings by all users in the current period of time we can predict availability of parking spaces in the near future
    * we can also inform users about frequency of bookings from other users

##### User account financial transactions
Overview:
* History of financial transactions on user account. For analytical purposes.
* Data are only appended to the table, no updates or deletes are allowed. So no locking is required.
* Table will be indexed by user_id, financial_transaction_id, timestamp and event_type. Other indexes would be added based on usage.
* Table will most likely be partitioned by date (timestamp rounded to full date).
* Table does not require audit trail because records are immutable.

Structure:
* `financial_transaction_id`: integer automatically increased (serial) unique financial transaction identifier
* `user_id`: integer user identifier
* `parking_lot_id`: integer parking lot identifier
* `tracking_event_id`: integer parking tracking event identifier connected with this event (entry id for usage, exit id for charging)
* `event_timestamp`: timestamp of the event
* `event_type`: type of the event
* `metadata`: JSON record
* `amount`: amount of money
* `currency`: currency of the transaction
* `account_balance`: current account balance
* `created_at`: timestamp when account was created
* `created_by`: ID of the user / system who created the record

Financial events:
* `usage_charged`: money charged per our due to usage of parking lot
  * this event will be triggered by pricing engine for every paid period of usage
* `usage_free`: free usage of parking lot
  * event triggered by pricing engine for every free period of usage
  * free usage can happen in cases like
    * some promotion campaigns either general or personalized (user can receive free usage for example for his birthday etc)
    * problems with parking lot or the whole system
    * if there is some option to use parking lot for free for example for employees
    * if there is some option like first 15 minutes are free / first hour is free etc
* `account_charged`: event physically taking money from user account
  * this event will be triggered by `exit` event
  * amount charged will be calculated by pricing engine as summary of all `usage_charged` and `usage_free` events
* `account_increased`: money send to account
  * this is real moment when money is added to the account - in many cases payment using card is actually delayed
* `account_decreased`: money send from account back to user
  * special event, this could be important in case user deletes account and we need to send him money back
  * or in case of wrong charge like double charge due to some bug in the system

Notes:
* Financial events will be created by pricing engine or other parts of the system.
* Corresponding financial events will be created in the same transaction as parking tracking events to ensure consistency.

#### Parking lot master record
Overview:
* Holds information about parking lot.
* Only one record per parking lot exists.
* Master record will be updated mainly during entry/exit events and also during manual parking lot updates.
* Table will be indexed by parking_lot_id. Other indexes would be added based on usage.
* Table will most likely not be partitioned.
* Record will locked during updates.

Structure:
* `parking_lot_id`: integer automatically increased (serial) unique parking lot identifier
* `parking_lot_name`: parking lot name
* `address`: parking lot address
* `capacity`: parking lot capacity
* `pricing_model_id`: pricing model identifier
* `blocked`: flag indicating if parking lot is blocked
* `blocked_reason`: reason why parking lot is blocked
* `blocked_timestamp`: timestamp when parking lot was blocked
* `full`: flag indicating if parking lot is full
* `full_timestamp`: timestamp when parking lot was full
* `created_at`: timestamp when parking lot was created
* `created_by`: identifier of the user / system who created the record
* `updated_at`: timestamp when parking lot master record was last time updated
* `updated_by`: identifier of the user / system who updated the record

Assumptions:
* Parking lot is an area designated for the parking of vehicles, usually outdoors and located near a building, shopping center, or public area.
* It typically consists of a paved surface with marked parking spaces. It's capacity is fixed and defined by the number of parking spaces.
* For different use cases we can have different types of parking lots - for passenger cars, for trucks, for buses, for motorcycles, for bicycles, for disabled people etc. These will require different handling by the system.

##### Parking lot master record audit events
Overview:
* Table contains history of changes on parking lot master record.
* Data are only appended to the table, no updates or deletes are allowed. So no locking is required.
* Table will be indexed by parking_lot_id, event_timestamp and event_type. Other indexes would be added based on usage.
* Table will most likely be partitioned by date (event_timestamp rounded to full date).

Structure:
* `audit_id`: integer automatically increased (serial) unique parking lot audit identifier
* `parking_lot_id`: integer parking lot identifier
* `event_timestamp`: timestamp of the event
* `event_type`: type of the event
* `metadata`: JSON record describing the event
* `capacity`: capacity of the parking lot after event

Parking lot master record audit events:
* `parking_lot_created`: parking lot created
  * sets initial capacity of the parking lot
* `parking_lot_updated`: parking lot updated
  * updates capacity of the parking lot
  * if there would be some limitations for example due to construction works
  * or if capacity increases due to adding new parking spaces
* `parking_lot_deleted`: parking lot deleted
  * for future growth of the system, some parking lot can be sold etc - to track this for the analysis
* `parking_lot_blocked`: parking lot blocked
  * parking lot can be temporarily out of service due to maintenance works etc
* `parking_lot_unblocked`: parking lot unblocked
  * parking lot is back in service
* `parking_lot_full`: parking lot full
  * ? this could be useful for the analysis, requires further discussion
* `parking_lot_revenue`: parking lot revenue per day
  * ? this could be useful for the analysis, requires further discussion

##### Parking lot tracking events
Overview:
* Tracking events on parking lot related to entry and exit of cars and connection with the system on parking lot.
* Data are only appended to the table, no updates or deletes are allowed. So no locking is required.
* Table will be indexed by parking_lot_id, user_id, timestamp and event_type. Other indexes would be added based on usage.
* Table will most likely be partitioned by date (timestamp rounded to full date).
* Table does not require audit trail as it is not possible to change the data.

Structure:
* `tracking_event_id`: integer automatically increased (serial) unique parking lot tracking event identifier
* `parking_lot_id`: integer parking lot identifier
* `user_id`: integer user identifier
* `event_timestamp`: timestamp of the event
* `event_type`: type of the event
* `metadata`: JSON record describing the event - for example entry method QR/NFC etc
* `capacity`: capacity of the parking lot AFTER the event

Tracking events:
* `entry`: car enters the parking lot (timestamp, user ID, parking lot ID, entry method (QR/NFC), financial transaction id)
  * even entry can trigger financial transaction in some cases - both decrease and increase
* `entry_refused`: when a user is denied entry to the parking lot or exit due to an invalid or deleted or blocked account (timestamp, user ID, parking lot ID, entry method (QR/NFC), metadata)
  * this event will not trigger financial transaction
  * entry gate display shall inform user about the reason of refusal
  * user must later receive detailed information by email or pusher notification into the app
* `exit`: car leaves the parking lot (timestamp, user ID, parking lot ID, duration, financial transaction id)
  * for common users this event will always trigger financial transaction
  * unless there will be some special cases like free parking for first 15 minutes / first 1 hour etc or free parking in case of some special events
* `connection_lost`: generated by main system when internet/network connection is lost
  * will require some heartbeat mechanism to detect this
* `connection_restored`: generated by main system when internet/network connection is restored
  * will require some heartbeat mechanism to detect this

Assumptions:
* All events are created by system. User input is not considered.
* Even with hundreds of parking spaces available on one parking lot, frequency of events for one specific parking lot is actually quite small. Only a few events per minute for one parking lot.
* Frequency will be limited by capacity of entrance/exit gates. How many cars can enter/exit parking lot per minute. Many parking lots in real life can just 1 entry and 1 exit gate. Sometimes with 2 lanes, very rarely with more lines.
* Frequency of events can grow only in case we start managing multiple parking lots. But even in this case, frequency of events will be still reasonably small.
* Data will be highly seasonal. Exact pattern will depend on type of parking lot.
  * For example parking lot for supermarket will have peaks during rush hours and in case of sales, Black Friday, days before Christmas etc.
  * But even in this scope frequency of events will be still quite small because we are still limited by capacity of gates.
* Cars stay in the parking lot for quite a long time - dozens of minutes or hours. Shorter stays are not common.

#### Pricing model master record
This part would require further discussion. Because business requirements are not clear.

Overview:
* Holds information about pricing model.
* One pricing model can be used for multiple parking lots if future versions.
* Record will be locked during update.
* Table will be indexed by pricing_model_id. Other indexes would be added based on usage.
* Table will most likely not need partitioning.

Structure:
* `pricing_model_id`: integer automatically increased (serial) unique pricing model identifier
* `name`: pricing model short name for internal use
* `description`: pricing model detailed description
* `basic_rate_price`: lowest price per hour for parking lot usage in this pricing model
* `current_rate_price`: always contains current price per hour for parking lot usage in this pricing model
* `peak_rate_price`: highest price per hour for parking lot usage in this pricing model - null when unlimited or not applicable
* `pricing_model_type`: type of the pricing model - `dynamic` or `static`
* `pricing_model_parameters`: JSON data describing changes in price over time -  null if price should not be recalculated
  * dynamic pricing model:
    * `periodicity`: how often price should be recalculated in minutes - 15 minutes by default
    * `formula`: formula for calculating price based on current capacity of the parking lot
  * static pricing model:
    * `hours`: for static model only - array of `hour` and `price` pairs - price for specific hour of the day
* `currency`: currency of the price
* `created_at`: timestamp of the creation of the pricing model
* `created_by`: ID of the user who created the pricing model
* `updated_at`: timestamp of the last update of the pricing model
* `updated_by`: ID of the user who last updated the pricing model

Pricing engine:
* Price calculation will be encapsulated in a separate part of service and can be developed and improved independently.

Pricing models:
* Dynamic pricing model based on current capacity of the parking lot - number of available spaces.
  * The price will be higher when the parking lot is almost full and lower when the parking lot is almost empty.
  * There will be some base price for parking lot usage.
  * Can have some free parking time for example first 15 minutes or 1 hour.
  * Example formula for implementation: `price = round( base_price * (1 + (total_capacity - available_spaces) / total_capacity), 0)`

* Fixed price for long term users or companies.
  * monthly subscription with a fixed price
  * discounts from normal price.
  * For example, we can offer a fixed price for companies.

* Static pricing model based on time of the day.
  * Simplification of dynamic pricing model.
  * The price will be higher during rush hours and lower during the night.
  * There will be some base price for parking lot usage.
  * Prices will be set arbitrarily based on business requirements.

* Free parking for some special occasions.
  * For example, free parking in case of some special events.

Open questions:
* In which moment we calculate price for parking lot usage?
  * User should now the price before entering the parking lot to be able to decide if he wants to use it or not.
  * If he stays for longer time and price decreases during his stay, will we charge him the lower price for remaining time?
  * We cannot charge him higher price for remaining time because this would be unfair and would discourage users from using the parking lot.
* Is it possible to have multiple pricing models for one parking lot?

Assumptions:
* To be able to implement some pricing model I assume that:
  * I will presume one price for parking lot usage for current hour for all users.
    * Price will be re-calculated based on current capacity of the parking lot every 15 minutes.
  * Standard way of calculating price for parking lot usage is to calculate price per hour so I will use this approach.
  * User is charged for every started hour of parking lot usage.
    * I will generate `usage_charged` event every hour for every user that is still in the parking lot.
    * For maintaining good relationship with users, there should be some time interval in the next hour when user can leave the parking lot without being charged for the next hour. For the sake of this PoC I assume that this interval is 5 minutes.
      * I.e. charging event will be generated every 6th minute of the hour.
  * Maximal price user can be charged per hour is price he received when entering the parking lot.
  * For maintaining good relationship with users, user will be charged less in next hours when price decreases due to more free parking spaces available.
* For the purpose of this technical challenge I presume very naive approach to pricing model. But since parameters of pricing model are stored in JSON format, it will be possible to relatively easily implement more complex pricing models in the future.

#### Pricing model audit record
Overview:
* Holds information about changes in pricing model.
* Records will be created every time pricing model is created of updated or deleted.
* Table will be indexed by pricing_model_id. Other indexes would be added based on usage.
* Table will be most likely partitioned by date - rounded event_timestamp column to day.

Structure:
* `audit_id`: integer automatically increased (serial) unique pricing model audit identifier
* `pricing_model_id`: integer unique pricing model identifier
* `event_timestamp`: timestamp of the event
* `event_type`: type of the event
* `metadata`: JSON data describing event
* `price`: price per charging period

Audit events:
* `pricing_model_created`: pricing model was created
* `pricing_model_updated`: pricing model was updated
* `pricing_model_deleted`: pricing model was deleted
* `price_changed`: price was changed for specific pricing model
  * special record will be created when pricing engine calculates new price for specific pricing model
  * change will be recorded also in the event `pricing_model_updated`
  * this special record simplifies querying data for analytics purposes

#### Price per user and parking lot
Overview:
* Holds information about current price for specific user and parking lot.
* Records exists only when user is currently in the parking lot.
* Only one record per user and parking lot can exist at the same time.
* Table will be indexed by user_id and parking_lot_id. Other indexes would be added based on usage.
* Table will not be partitioned because it will be small.
* Rules for updating records are listed in assumptions.
* Record will be locked during updates.

Structure:
* `price_id`: integer automatically increased (serial) unique price identifier
* `user_id`: integer unique user identifier
* `parking_lot_id`: integer unique parking lot identifier
* `pricing_model_id`: integer unique pricing model identifier
* `tracking_event_id`: integer tracking event identifier - id of entry event for this user and parking lot
* `price`: price per hour
* `currency`: currency of the price
* `created_at`: timestamp of the creation of the price
* `created_by`: ID of the user / system who created the price
* `updated_at`: timestamp of the last update of the price
* `updated_by`: ID of the user / system who last updated the price

Assumptions:
* Record is created when user enters the parking lot and is updated when price decreases due to more free parking spaces available.
* Price is never increased. Maximal price user can be charged per hour is price he received when entering the parking lot.
* Record is deleted when user leaves the parking lot and is charged for his stay.
* Price stored in this table is used for charging user for parking lot usage for current charging period.
* Changes are recorded in audit table.

##### Price per user and parking lot auditing events
Overview:
* Holds information about price changes for specific user and parking lot.
* Records are created when user enters parking lot or price decreases.
* Records are only added, never updated or deleted. So no locking is required.
* Table will be indexed by user_id and parking_lot_id.
* Table will be partitioned by date (rounded event_timestamp to day).

Structure:
* `audit_id`: integer automatically increased (serial) unique audit identifier
* `event_timestamp`: timestamp of the price change
* `event_type`: type of the event
* `price_id`: integer unique price identifier
* `user_id`: integer unique user identifier
* `parking_lot_id`: integer unique parking lot identifier
* `pricing_model_id`: integer unique pricing model identifier
* `tracking_event_id`: integer tracking event identifier - id of entry event for this user and parking lot
* `price`: price per hour
* `currency`: currency of the price
* `metadata`: JSON data with additional information about the event

Events:
* `entry`: user entered the parking lot and price record for user and parking lot was created
* `price_changed`: price decreased due to more free parking spaces available
* `exit`: user left the parking lot and price record was deleted

### Technologies:
- For PoC:
  - We can use a very simple architecture because frequency of data will be quite small.

- For more complicated use cases (see below):
  - Apache Kafka for event streaming and processing. This allows real-time monitoring and analysis of events.
  - More advanced data warehouse like Google BigQuery or Amazon Redshift for storing and analyzing the events data.

1. Backend system design and data model for the operational system:

   Backend system design:
   - Use a RESTful API built with a web framework like Django, Flask, or Express.js for handling user requests.
   - Use a relational database like PostgreSQL, MySQL, or MariaDB for storing user information and parking lot state.
      - Based on my previous experiences I would recommend PostgreSQL. Since it has very mature both OLTP and OLAP capabilities.

   Technologies:
   - For the API: Django, Flask, or Express.js. ?
   - For the database: PostgreSQL

2. Combining operational and analytical architectures:

  - Live system needs to just see data for the current day and maybe previous day - for cases when user enters the parking lot in the evening and leaves in the morning.
  - Older audit data can be archived to a data warehouse for data analysis.
  - For the PoC we presume copying the whole yesterday's partition to the data warehouse every day.
  - If necessary we can implement incremental updates of the data warehouse over the day for the current day.
  - Master records which will could be repeatedly updated will be stored in the operational database.
  - Analytical system needs to see data for the whole history, today could be questionable.

3. Development lifecycle, test, and deployment automation:

   - Development lifecycle:
     - Agile methodologies like Scrum or Kanban for iterative development and continuous improvement will be used.
     - We will use a project management tool like Jira or Trello to manage the development process.
   - Version control:
     - Git will be used for version control and collaboration among the development team.
   - Quality of code:
     - Where ever possible we will use properly set linters to ensure the quality of the code.
   - Continuous integration:
     - We can use tools like Jenkins, Google Cloud build and similar to automatically build and test your code whenever changes are either pushed to the repository or merged to the main branch or both.
   - Automated testing:
     - We will write unit tests, integration tests, and end-to-end tests to ensure the quality of your code. Use testing frameworks like pytest (Python), JUnit (Java), or Mocha (JavaScript).
   - Deployment automation:
     - Solution will be developed in containers (Docker) and orchestration tool like Kubernetes will be used to automate the deployment process.
   - Monitoring and alerting:
     - The performance and health of the whole system will be monitored using Prometheus, Alertmanager and Grafana.
     - Different alerts and warnings will be set to notify the team of any issues.

## Implementation of the solution

Based on pragmatic principle mentioned above, I will first discuss a PoC (Proof of Concept) solution. This PoC will be a simple solution that will be able to handle the most basic use cases. After that, I will iterate over the PoC and improve it by adding new features and extending the functionality for handling more complex use cases.

### Technical overview
#### Mobile app
Mobile app must handle the following tasks:
* Creation / update / deletion of user account
* Show QR code for user account for entering / exiting parking lot. Content of QR code should be not trivial to prevent frauds.
* Show status of user account - current balance, list of transactions, list of parking lots used in the past.
  * For advanced versions also list of parking lots used in the future (if user already booked parking lot in advance)
* Show list of available parking lots with their current state based on user location
* Show details of selected parking lot including indication of frequency of current traffic on parking lot and prediction of available spaces in the next 30 minutes/1 hour.
* Mobile app must indicate if there is a problem with network connection on specific parking lot and must indicate that system works offline and therefore app cannot show current state of parking lot.

#### Parking lot devices
Technical devices stationary on parking lot must be able to handle the following tasks:
* Entry gate must be able to show Green light if new car can enter parking lot or Red light if car cannot enter parking lot because it is full.
* Scan QR and validate if user can enter parking lot - i.e. if user has a valid account and if user has enough money on his account to be able to enter parking lot or has payment model which allows him to enter parking lot due to subscription or "pay after the fact" model.
  * System must be able to handle cases when user has no internet connection and must be able to validate user account locally.
* Entry/exit gate must be able to recognize if car is present to prevent frauds.
* Validate if parking lot really has available space for user to enter
* Handle possible network issues by storing events locally and sending them to the server when network is available again.

#### PoC solution
**Assumptions for PoC:**
- In PoC we manage only 1 parking lot but data model will be prepared to handle multiple lots.
- There will be only one type of parking spaces available - standard parking space for passenger cars.
- Pricing model will be very simple - just dynamic pricing based on capacity.
- There are no dedicated / reserved parking spaces for specific users. Any user can park in any parking space. Only limitation for using our parking lot is that the user must have a valid account with us or thousands
- We presume all users will be always able to use mobile app to enter/exit parking lot. We will not consider any other entry/exit methods for PoC.
- For PoC we will consider only one payment method per user. And for the sake of simplicity we presume that user must charge money in advance to be able to use our parking lot. We will check for minimum amount available to be able to enter the parking lot. If the user does not have enough money on his account, he will not be able to enter the parking lot.
- There will no accounts for multiple users. We presume one user ID per one App. One user can have multiple Apps on multiple devices, but for one entry to the parking lot can use only one App at the time.

**More complex use cases:**
- In the future we will manage multiple parking lots.
- This way we will have thousands of parking spaces available which will significantly increase the frequency of events. Although frequency for one specific parking lot will still be quite small.
  - With dozens or hundreds parking lots we can expect even hundreds of events per minute in peak hours.
- On some parking lots we will have dedicated / reserved parking spaces for specific users. These must stay empty if the owners are not using them.
- On some parking lots we will have specialized parking spaces for specific types of vehicles - e.g. electric cars, trucks, etc. Or for specialized type of clients like disabled people. These will have different pricing models.
- User can have multiple payment methods. And for selected ranked users we will allow negative state of account and payments after the fact.
- We can allow group accounts for multiple users. This way multiple users could use the same account to enter the parking lot. This could be useful for companies with multiple employees.
- We will consider other entry/exit methods like recognition of license plates on cars. But still user must have a valid account with us and license plate must be registered in our system in that account.
- We will allow multiple pricing models based on the parking lot location, type of parking space, time of the day, day of the week, season, etc.
- We will allow discounts for long term users. or fixed monthly subscription which will allow users to use our parking lots without any additional charges.

