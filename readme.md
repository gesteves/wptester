# wptester

A simple way to run WebPageTest tests and log them in Librato.

![](http://i.imgur.com/v4JNswc.png)

## Requirements

* A [Heroku](https://www.heroku.com/) account, and the [Heroku CLI](https://devcenter.heroku.com/articles/heroku-cli)
* A [Librato](https://www.librato.com/) account, and a record-only [API token](https://metrics.librato.com/account/tokens)
* A [WebPageTest](https://www.webpagetest.org/getkey.php) API key

## Installation

Click this button to deploy directly to Heroku:

[![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

After it's deployed, make sure [dyno metadata](https://devcenter.heroku.com/articles/dyno-metadata) is enabled for your new app. In your terminal, run:

```
$ heroku labs:enable runtime-dyno-metadata -a <app name>
```

## Usage

Once your app is deployed and running, go to the Resources page in the Heroku dashboard and open the Heroku Scheduler. Add a new job, make it daily (or hourly of you want, but keep in mind WPT only allows a limited number of tests each day, so it's kind of overkill), and make it run this rake task:

```
rake wpt:request SITE_URL=http://... SOURCE=some-label
```

The `SITE_URL` is the URL of the page you want to test in WPT.

`SOURCE` is what you'll use in Librato to filter your metrics (e.g. if the page you're testing is your home page, you can put `homepage` as the source).

You can test multiple pages by creating more scheduled jobs, just remember that WPT only allows a certain number of tests per day. If you set up multiple tests, remember to use different sources in the rake task so you can filter the metrics in Librato.

Save the scheduled jobs, let them run, and then you can set up your charts however you like in Librato.

## To do

* Allow testing different locations, browser/device profiles, network conditions, etc. Right now it tests desktop Chrome on cable from Virginia by default.
* Allow using a private WPT instance
