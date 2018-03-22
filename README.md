# B2B Design & Development VVV Custom site template
Customized for standard B2B development

# Configuration

### The minimum required configuration:

```
my-site:
  repo: https://github.com/b2bdd/custom-site-template.git
  hosts:
    - my-site.test
```

## Standard Configuration Options

```
hosts:
    - foo.test
    - bar.test
    - baz.test
```
Defines the domains and hosts for VVV to listen on.
The first domain in this list is your sites primary domain.

```
custom:
    site_title: My Awesome Dev Site
```
Defines the site title to be set upon installing WordPress.

```
custom:
    wp_version: 4.6.4
```
Defines the WordPress version you wish to install.
Valid values are:
- nightly
- latest
- a version number

Older versions of WordPress will not run on PHP7, see this page on [how to change PHP version per site](https://varyingvagrantvagrants.org/docs/en-US/adding-a-new-site/changing-php-version/).

```
custom:
    wp_type: single
```
Defines the type of install you are creating.
Valid values are:
- single
- subdomain
- subdirectory

```
custom:
    db_name: super_secet_db_name
```
Defines the DB name for the installation.


## Wordmove Options
Use the following variables under custom to customize the Movefile included with the new site. Any variables which include special characters should be wrapped in double quotes, i.e. "!43dmISlso&%dBVs"

```
client_name:
  repo: https://github.com/b2bdd/custom-site-template.git
  hosts:
    - my-site.test
  custom:
    staging_database: db_name
    staging_database_user: username
    staging_database_pass: password
    staging_server_path: /path/to/wordpress
    staging_server: 1.2.3.4
    staging_server_user: ssh_username
    staging_server_pass: ssh_password
```