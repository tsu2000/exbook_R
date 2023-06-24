# exbook_R

A Shiny web application tailored towards beginner programmers that allows users to practice their R programming skills. Based off the `exbook` package in Python [here](https://pypi.org/project/exbook/).

![image](https://github.com/tsu2000/exbook_R/assets/106811131/95ce06fb-30c2-492d-9b4c-703c7ef2e16f)

There are currently **36** questions available for practice.

**Application details:**
- Users are free to submit pull requests to improve the overall application experience.
- Data for all questions in the web app can be found in the `question_bank.json` file.
- The difficulty levels are just a suggestion as they are based on beginners' programming ability, and some 'Medium' and 'Hard' difficulty questions may actually be equivalent to a LeetCode 'Easy'.
- GitHub Actions automatically re-deploys the web app from [shinyapps.io](https://www.shinyapps.io) (where the site is hosted) when a commit is made to `main` and restarts the application when changes are made to the `question_bank.json` file. 
- There are currently no plans to turn the web app into an R package.

**Link to web app:**

[![](https://img.shields.io/badge/Shiny-shinyapps.io-blue?style=flat&labelColor=white&logo=RStudio&logoColor=blue)](https://tsu2000.shinyapps.io/exbook/)
