# Technical Challenge L.

* Repository contains my work on technical challenge for the company L. Hiring process was unfortunately unsuccessful. I turned out during discussion of my work that they expected solution tailored more to their environment. Which of course I was not able to provide since in that stage of hiring process I had only very limited information about their data platform. But still I believe I did a good work so I am sharing it here.

* The whole challenge was set to be solved in 3 days. So I did pragmatically as much as possible. Now when hiring process ended I decided to enhance these solutions to be able to show them as fully fledged projects for my future reference.

* Tasks and solutions are in the directories `task_1`, `task_2`, `task_3` and `task_4`.
  * For the simplicity all descriptions, comments and explanations for each task are in the README files in each task directory.

* If required technical diagrams have been created using online tool Miro and exported as pictures.
  * README files indicates if some Miro board exist for specific task and link is included.

## Missing things

### Task 4
- authentication:
  - I omitted authentication for the simplicity in PoC
  - most likely some kind of token based authentication would be used to avoid frauds
  - we can use some kind of JWT token (JSON Web Token) which is signed by the server and contains some information about the user

- predictive model:
  - For PoC I implemented only simple ARIMA (AutoRegressive Integrated Moving Average) model, which is a popular time-series forecasting model implemented in Python for predicting future values based on past observations.
  - In real world we would use some more advanced model, for example LSTM (Long Short-Term Memory) model, which is a type of recurrent neural network (RNN) that can learn the order dependence between items in a sequence.
  - Another possibility would be SARIMA model - Seasonal AutoRegressive Integrated Moving Average model, which is an extension of ARIMA that explicitly supports univariate time series data with a seasonal component.
