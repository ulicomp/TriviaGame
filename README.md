# Project 5 - Trivia Game

Submitted by: **Ulises Alberto Cheong Borges**

**Trivia Game** is a SwiftUI trivia application that allows users to configure and complete quizzes using questions dynamically retrieved from the Open Trivia Database API. Users can customize the number of questions, category, difficulty, and question type, then answer questions against a countdown timer, submit their quiz, review their results, and see detailed answer feedback.

Time spent: **6** hours spent in total

## Required Features

The following **required** functionality is completed:

- [x] App launches to an Options screen where the user can modify the types of questions presented when the game starts.
- [x] User can select the number of questions.
- [x] User can select the category of questions.
- [x] User can select the difficulty of questions.
- [x] User can select the question type: Multiple Choice or True/False.
- [x] User can tap a button to start the trivia game.
- [x] Questions and answers are presented using a Card view.
- [x] Selected choices are visually marked when the user taps an answer.
- [x] Correct or incorrect answers are not revealed before submission.
- [x] User can submit their choices.
- [x] User is presented with their score after submitting the trivia game.

## Optional Features

The following **optional** features are implemented:

- [x] After submitting, the user's answers are marked as correct or incorrect alongside the score.
  - Correct selections are highlighted in green.
  - Incorrect selections are highlighted in red.
  - The correct answer is displayed when the user answers incorrectly.
  - Unanswered questions are identified and the correct answer is shown.

- [x] A timer places a time limit on the quiz.
  - The timer allows 30 seconds per question.
  - Remaining time is displayed during gameplay.
  - The timer stays accurate when the app moves between the background and foreground.

- [x] The quiz is automatically submitted when the timer expires.
  - Current selections are submitted automatically.
  - Unanswered questions count as incorrect.
  - The final score and answer review remain available after automatic submission.

## Additional Features

The following **additional** features are implemented:

- [x] Questions are dynamically retrieved from the Open Trivia Database API using REST requests and user-selected query parameters.

- [x] Open Trivia Database response codes are handled with recoverable error states.

- [x] HTML entities returned by the API are decoded into readable Unicode text, including accented and international characters.

- [x] Multiple-choice answers are shuffled once when the quiz is prepared and remain in a stable order throughout the quiz.

- [x] True/False questions always display stable True and False answer choices.

- [x] Users can navigate backward and forward through questions while preserving previously selected answers.

- [x] Users may leave questions unanswered and receive a confirmation before manually submitting.

- [x] A dedicated Results screen displays the score, percentage, number correct, answered questions, and unanswered questions.

- [x] Perfect-score quizzes display the user's completion time.
  - Completion time is shown only when the user answers every question correctly.
  - Completion time does not affect the score or ranking.

- [x] A Review Answers screen allows users to review every submitted question and see correct, incorrect, and unanswered responses.

- [x] Play Again retrieves a fresh set of trivia questions using the current configuration.

- [x] Change Options allows users to return to the setup screen while preserving their selected configuration.

- [x] The timer uses a deadline-based system so backgrounding the app does not give the player additional time.

- [x] The interface includes a custom purple-and-white visual design with rounded cards, progress indicators, polished result screens, and responsive layouts.

- [x] A custom 1024×1024 app icon is included.

- [x] Accessibility support includes descriptive labels, selected states, timer descriptions, score information, and non-color indicators for correct and incorrect answers.

## Video Walkthrough

Here's a walkthrough of the implemented user stories:

[Trivia Game Video Walkthrough](https://youtube.com/shorts/2DDhM0_INe4?feature=share)

## Notes

Some challenges encountered while building the app:

- Open Trivia Database returns HTML-encoded text, including named and numeric entities. A decoding layer was added so questions and answers display correctly with punctuation, accented characters, and international text.

- Some combinations of category, difficulty, and question type may legitimately return no questions because the Open Trivia Database does not contain enough questions matching those specific options. The app handles these API responses gracefully without treating them as application failures.

- Keeping answer choices stable required shuffling multiple-choice answers only once during quiz preparation instead of during SwiftUI rendering.

- The countdown timer required careful state management so manual submission and automatic expiration could never submit the same quiz twice.

- The timer uses an absolute deadline so time remains accurate when the application is backgrounded and foregrounded.

- Post-submission answer review was designed separately from the active quiz so correct and incorrect answers are never revealed before submission.

- The interface was designed to remain readable for long questions and answers while maintaining a consistent purple-and-white card-based visual style.

## License

Copyright 2026 Ulises Alberto Cheong Borges

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at:

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
