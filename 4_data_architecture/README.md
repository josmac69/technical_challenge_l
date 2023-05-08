# Data Architecture Challenge

## Task

We are managing parking lots that a client can check with a mobile app. An app can tell the drive if a parking is full or not. On entering/leaving the parking a client can scan QR/NFC code on entrance machines and the cost must be automatically charged when leaving parking. We are interested in monitoring when the parking is full or empty to modify prices accordingly. We also would like to create a predictive model that learns when a client is going to the parking to send him a push message informing how many places are left or if the parking is full.

1. What tracking events would you propose? What data model for event analysis? What technologies?
2. How would you design the Backend system? What data model for the Operational system? What technologies?
3. Explain how to combine the operational architecture with the analytical one?
4. Could you propose a process to manage the development lifecycle? And the test and deployment automation?

## Solution

### General overview of the solution
The whole task is very narrowly defined. Data gathered by the app are very simple and relational by design.
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

Based on pragmatic principle mentioned above, I will first create a PoC (Proof of Concept) solution. This PoC will be a simple solution that will be able to handle the most basic use cases. After that, I will iterate over the PoC and improve it by adding new features and extending the functionality for handling more complex use cases.

**Assumptions for PoC:**
- In PoC we are managing only 1 parking estate.
- The whole parking estate is a physical location with a fixed capacity.
- There will be only one type of parking lot available - standard parking lot for passenger cars.
- We will use dynamic pricing model - price will depend on the current state of the parking estate (number of available spaces). The price will be higher when the parking estate is almost full and lower when the parking estate is almost empty.
- There will be no discounts for long term users.
- Even with hundreds of parking lots available, frequency of events is actually quite small in order of minutes or hours.
- Cars stay in the parking lots for quite a long time - dozens of minutes or hours. Shorter stays are not common.
- Data will be highly seasonal, with peaks during rush hours. But even in this scope frequency of events is still quite small.
- There are no dedicated / reserved parking lots for specific users. Any user can park in any parking lot. Only limitation for using our parking lots is that the user must have a valid account with us.or thousands
- We presume all users will be always able to use mobile app to enter/exit parking lot. We will not consider any other entry/exit methods for PoC.
- For PoC we will consider only one payment method per user. And for the sake of simplicity we presume that user must charge money in advance to be able to use our parking lots. We will check for minimum amount available to be able to enter the parking lot. If the user does not have enough money on his account, he will not be able to enter the parking estate.
- There will no accounts for multiple users. We presume one user ID per one App. One user can have multiple Apps on multiple devices, but for one entry to the parking estate can use only one App at the time.

**More complex use cases:**
- In the future we will manage multiple parking estates.
- This way we will have thousands of parking lots available which will significantly increase the frequency of events. So with dozens or hundreds parking estates we can expect even hundreds of events per minute.
- On some parking estates we will have dedicated / reserved parking lots for specific users. These must stay empty if the owners are not using them.
- On some parking estates we will have specialized parking lots for specific types of vehicles (e.g. electric cars, trucks, etc.). With different pricing models and different capacity.
- User can have multiple payment methods. And for selected users ranked by their loyalty and amount spent (or other criteria)  we will allow them to enter the parking estate even if they do not have enough money on their account. We will charge them later. But there will be some limit for the negative balance.
- We can allow group accounts for multiple users. This way multiple users could use the same account to enter the parking estate. This could be useful for companies with multiple employees.
- We will consider other entry/exit methods like recognition of license plates on cars. But still user must have a valid account with us and license plate must be registered in our system in that account.
- We will allow multiple pricing models based on the parking estate location, type of parking lot, time of the day, day of the week, season, etc.
- We will allow discounts for long term users. or fixed monthly subscription which will allow users to use our parking lots without any additional charges.

