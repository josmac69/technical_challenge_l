# Data Architecture Challenge

## Task

We are managing parking lots that a client can check with a mobile app. An app can tell the drive if a parking is full or not. On entering/leaving the parking a client can scan QR/NFC code on entrance machines and the cost must be automatically charged when leaving parking. We are interested in monitoring when the parking is full or empty to modify prices accordingly. We also would like to create a predictive model that learns when a client is going to the parking to send him a push message informing how many places are left or if the parking is full.

1. What tracking events would you propose? What data model for event analysis? What technologies?
2. How would you design the Backend system? What data model for the Operational system? What technologies?
3. Explain how to combine the operational architecture with the analytical one?
4. Could you propose a process to manage the development lifecycle? And the test and deployment automation?

## Solution

### General overview of the solution
The definition of the whole task is would require further discussions to understand better all the details.
But since this is a technical challenge I will set some assumptions and provide solution based on them.

Data gathered by the app are very simple and relational by design.
We need to use transactional database with strong consistency to avoid over booking of parking lots.

### General features of the solution
In this part I gathered just some thoughts about the solution. The whole solution is described in the next section.
The whole process of designing the solution was based on the pragmatic principle - [Make it Work, Make It Right, Make It Fast](https://wiki.c2.com/?MakeItWorkMakeItRightMakeItFast)

1. Tracking events and data model for event analysis:

   Tracking events:
   a. `parking_lot_state`: This event should track the current state of each parking lot (number of available spaces, total capacity).
   b. `check_in`: This event should track when a car enters the parking lot (timestamp, user ID, parking lot ID, entry method (QR/NFC)).
   c. `exit`: This event should track when a car leaves the parking lot (timestamp, user ID, parking lot ID, duration, amount charged).

   Data model for event analysis:
   We can use a star schema for event analysis, with a fact table containing the event details (event type, timestamp, user ID, parking lot ID, duration, amount charged) and dimension tables containing information about users, parking lots, and time.

   Technologies:
   - For PoC:
     - We can use even a very simple architecture because frequency of data will be quite small.
   - For more complicated use cases (see below):
     - Apache Kafka for event streaming and processing. This allows real-time monitoring and analysis of events.
     - More advanced data warehouse like Google BigQuery or Amazon Redshift for storing and analyzing the events data.

2. Backend system design and data model for the operational system:

   Backend system design:
   - Use a RESTful API built with a web framework like Django, Flask, or Express.js for handling user requests. ?
   - Use a relational database like PostgreSQL, MySQL, or MariaDB for storing user information and parking lot state.
      - Based on my previous experiences I would recommend PostgreSQL. Since it have very mature both OLTP and OLAP capabilities.

   Data model for the operational system:
   - Users table:
     - Stores user information - user ID, name, email, payment information
   - Parking lots table:
     - stores parking lot information - parking lot ID, location, capacity, current available spaces, pricing model ?
   - Transactions table:
     - stores information about each transaction - transaction ID, user ID, parking lot ID, entry time, exit time, amount charged ?

   Technologies:
   - For the API: Django, Flask, or Express.js. ?
   - For the database: PostgreSQL

3. Combining operational and analytical architectures:

   Apache NiFi or AWS Glue?

4. Development lifecycle, test, and deployment automation:

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

#### Implementation of the solution

Based on pragmatic principle mentioned above, I will first discuss a PoC (Proof of Concept) solution. This PoC will be a simple solution that will be able to handle the most basic use cases. After that, I will iterate over the PoC and improve it by adding new features and extending the functionality for handling more complex use cases.

##### Analysis

###### System overview
- Parking lot is an area designated for the parking of vehicles, usually outdoors and located near a building, shopping center, or public area.
It typically consists of a paved surface with marked parking spaces. It's capacity is fixed and defined by the number of parking spaces.
- Even with hundreds of parking spaces available on one parking lot, frequency of events for one specific parking lot is actually quite small. Only a few events per minute for one parking lot. Frequency will be limited by capacity of entrance/exit gates. How many cars can enter/exit parking lot per minute. Many parking lots in real life can just 1 entry and 1 exit gate. Sometimes with 2 lanes, very rarely with more lines.
  - Frequency of events can grow only in case we start managing multiple parking lots.
- Data will be highly seasonal, with peaks during rush hours and in case of sales, Black Friday, days before Christmas etc. But even in this scope frequency of events is still quite small because we are still limited by capacity of gates.
- Cars stay in the parking lot for quite a long time - dozens of minutes or hours. Shorter stays are not common.
- For different use cases we can have different types of parking lots - for passenger cars, for trucks, for buses, for motorcycles, for bicycles, for disabled people etc. These will require different handling by a system.

###### Pricing model
Price calculation will be encapsulated in a separate part of service and can be developed and improved independently.
- Dynamic pricing model is required for common users.
  - Price will depend on the current state of the parking lot - number of available spaces.
  - The price will be higher when the parking lot is almost full and lower when the parking lot is almost empty.
  - One possible way of implementing price could be for example: `price = base_price * (1 + (total_capacity - available_spaces) / total_capacity)`.
- For long term users we can use a different price model. For example, we can offer a monthly subscription with a fixed price or discounts from normal price.

- Pricing model relates to the execution of payments.
  - For new comers we can require to charge money in advance to be able to use our parking lots. Or we can subtract money from their electronic wallet associated with our account.
  - For long term users or for companies we can allow to pay after the fact. Account will accumulate required amount and system will send them an invoice at the end of the month.

###### Authentication


##### Technical overview
**Mobile app**
Mobile app must handle the following tasks:
* Creation / update / deletion of user account
* Show QR code for user account for entering / exiting parking lot. Content of QR code should be not trivial to prevent frauds.
* Show status of user account - current balance, list of transactions, list of parking lots used in the past.
  * For advanced versions also list of parking lots used in the future (if user already booked parking lot in advance)
* Show list of available parking lots with their current state based on user location
* Show details of selected parking lot including indication of frequency of current traffic on parking lot and prediction of available spaces in the next 30 minutes/1 hour.
* Mobile app must indicate if there is a problem with network connection on specific parking lot and must indicate that system works offline and therefore app cannot show current state of parking lot.

**Parking lot devices**
Technical devices stationary on parking lot must be able to handle the following tasks:
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

