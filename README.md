Reportbooru is a collection of services for reporting on [Danbooru](https://danbooru.donmai.us). It includes the following functionality:

* Search hits
* Missed search hits
* Search trends
* Common searches
* User similarity reports
* Exporting data to Google BigQuery
* Calculating related tags
* User performance reports

The web frontend is a standard Rails application. Reportbooru also runs daemon processes that listen on Amazon SQS for jobs.

You can deploy using Capistrano. It's recommended you fork this project and
modify the following files:

* config/deploy/production.rb
* .env

A sample .env file called .env-SAMPLE is included in the project. The .env
file itself is symlinked during deployment so you should create a version on
the server at /var/www/reportbooru/shared/.env.
