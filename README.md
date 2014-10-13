#Amazon EB deployment for Wercker.com


[![wercker status](https://app.wercker.com/status/71d5d56bbabd14e663bd6a792dbf2220/m "wercker status")](https://app.wercker.com/project/bykey/71d5d56bbabd14e663bd6a792dbf2220)

> Please note: This requires you to have an already existing Elastic Beanstalk application and environment in place, it will not run a startup procedure.

* `key` (required) Credentials key provided by amazon.
* `secret` (required) Credentials key secret provided by amazon
* `app_name` (required) Name of the application.
* `env_name` (required) Name of the application environment you wish to deploy to.
* `commit_message` (required) Source Git commit message for EB deployment version label.  
* `region` (optional) Region that your elastic beanstalk instance lives in, defaults to us-west-2.


```yml
deploy:
    steps:
        - patrickwolleb/elastic-beanstalk-deploy:
            key: $AMAZON_KEY
            secret: $AMAZON_SECRET_KEY
            app_name: My Application
            env_name: production
            commit_message : 'some string'
            region: us-west-2
```
