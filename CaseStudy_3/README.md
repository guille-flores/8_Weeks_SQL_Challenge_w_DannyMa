# Case Study #3 - Foodie-Fi

![Danny Ma Case Study #3 Foodie image](https://8weeksqlchallenge.com/images/case-study-designs/3.png)

## Introduction
Subscription based businesses are super popular and Danny realised that there was a large gap in the market - he wanted to create a new streaming service that only had food related content - something like Netflix but with only cooking shows!

Danny finds a few smart friends to launch his new startup Foodie-Fi in 2020 and started selling monthly and annual subscriptions, giving their customers unlimited on-demand access to exclusive food videos from around the world!

Danny created Foodie-Fi with a data driven mindset and wanted to ensure all future investment decisions and new features were decided using data. This case study focuses on using subscription style digital data to answer important business questions.

## Available Data
Danny has shared the data design for Foodie-Fi and also short descriptions on each of the database tables - our case study focuses on only 2 tables but there will be a challenge to create a new table for the Foodie-Fi team.

All datasets exist within the foodie_fi database schema - be sure to include this reference within your SQL scripts as you start exploring the data and answering the case study questions.

## Entity Relationship Diagram

![plans image](https://8weeksqlchallenge.com/images/case-study-3-erd.png)

Customers can choose which plans to join Foodie-Fi when they first sign up.

Basic plan customers have limited access and can only stream their videos and is only available monthly at $9.90

Pro plan customers have no watch time limits and are able to download videos for offline viewing. Pro plans start at $19.90 a month or $199 for an annual subscription.

Customers can sign up to an initial 7 day free trial will automatically continue with the pro monthly subscription plan unless they cancel, downgrade to basic or upgrade to an annual pro plan at any point during the trial.

When customers cancel their Foodie-Fi service - they will have a churn plan record with a null price but their plan will continue until the end of the billing period.

|plan_id	|plan_name|	price|
|--|--|--|
|0	|trial|	0|
|1	|basic monthly|	9.90|
|2	|pro monthly|	19.90|
|3	|pro annual|	199|
|4|	churn	|null|


Customer subscriptions show the exact date where their specific plan_id starts.

If customers downgrade from a pro plan or cancel their subscription - the higher plan will remain in place until the period is over - the start_date in the subscriptions table will reflect the date that the actual plan changes.

When customers upgrade their account from a basic plan to a pro or annual pro plan - the higher plan will take effect straightaway.

When customers churn - they will keep their access until the end of their current billing period but the start_date will be technically the day they decided to cancel their service.

| customer_id | plan_id | 	start_date|
|--|--|--|
| 1 | 0 | 	2020-08-01|
| 1 | 1 | 	2020-08-08|
| 2 | 0 | 	2020-09-20|
| 2 | 3 | 	2020-09-27|
| 11 | 0 | 	2020-11-19|
| 11 | 4 | 	2020-11-26|
| 13 | 0 | 	2020-12-15|
| 13 | 1 | 	2020-12-22|
| 13 | 2 | 	2021-03-29|
| 15 | 0 | 	2020-03-17|
| 15 | 2 | 	2020-03-24|
| 15 | 4 | 	2020-04-29|
| 16 | 0 | 	2020-05-31|
| 16 | 1 | 	2020-06-07|
| 16 | 3 | 	2020-10-21|
| 18 | 0 | 	2020-07-06|
| 18 | 2 | 	2020-07-13|
| 19 | 0 | 	2020-06-22|
| 19 | 2 | 	2020-06-29|
| 19 | 3 | 	2020-08-29|

## Interactive SQL Instance
You can use the embedded DB Fiddle below to easily access these example datasets - this interactive session has everything you need to start solving these questions using SQL.

You can click on the Edit on DB Fiddle link on the top right hand corner of the embedded session below and it will take you to a fully functional SQL editor where you can write your own queries to analyse the data.

You can feel free to choose any SQL dialect you’d like to use, the existing Fiddle is using PostgreSQL 13 as default.

Serious SQL students will have access to the same relevant schema SQL and example solutions which they can use with their Docker setup from within the course player!

<iframe src="https://embed.db-fiddle.com/385cbacc-36ad-46c4-978b-1cf5795b41bd"></iframe>
