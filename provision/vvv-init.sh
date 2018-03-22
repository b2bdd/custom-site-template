#!/usr/bin/env bash
# Provision WordPress Stable

DOMAIN=`get_primary_host "${VVV_SITE_NAME}".test`
DOMAINS=`get_hosts "${DOMAIN}"`
SITE_TITLE=`get_config_value 'site_title' "${DOMAIN}"`
WP_VERSION=`get_config_value 'wp_version' 'latest'`
WP_TYPE=`get_config_value 'wp_type' "single"`
STAGING_DB_NAME=`get_config_value 'staging_database' "${VVV_SITE_NAME}"`
STAGING_DB_USER=`get_config_value 'staging_database_user' "${VVV_SITE_NAME}"`
STAGING_DB_PASS=`get_config_value 'staging_database_pass' "${VVV_SITE_NAME}"`
STAGING_SERVER_PATH=`get_config_value 'staging_server_path' '/full/server/path/here'`
STAGING_SERVER=`get_config_value 'staging_server' '1.2.3.4'`
STAGING_SERVER_USER=`get_config_value 'staging_server_user' 'username'`
STAGING_SERVER_PASS=`get_config_value 'staging_server_pass' 'password'`
DB_NAME=`get_config_value 'db_name' "${VVV_SITE_NAME}"`
DB_NAME=${DB_NAME//[\\\/\.\<\>\:\"\'\|\?\!\*-]/}

# Make a database, if we don't already have one
echo -e "\nCreating database '${DB_NAME}' (if it's not already there)"
mysql -u root --password=root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME}"
mysql -u root --password=root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO wp@localhost IDENTIFIED BY 'wp';"
echo -e "\n DB operations done.\n\n"

# Nginx Logs
mkdir -p ${VVV_PATH_TO_SITE}/log
touch ${VVV_PATH_TO_SITE}/log/error.log
touch ${VVV_PATH_TO_SITE}/log/access.log

# Install and configure the latest stable version of WordPress
if [[ ! -f "${VVV_PATH_TO_SITE}/htdocs/wp-load.php" ]]; then
  echo "Downloading WordPress..."
	noroot wp core download --version="${WP_VERSION}"
fi

if [[ ! -f "${VVV_PATH_TO_SITE}/htdocs/wp-config.php" ]]; then
  echo "Configuring WordPress Stable..."
  noroot wp core config --dbname="${DB_NAME}" --dbuser=wp --dbpass=wp --quiet --extra-php <<PHP
define( 'WP_DEBUG', true );
PHP
fi

if ! $(noroot wp core is-installed); then
  echo "Installing WordPress Stable..."

  if [ "${WP_TYPE}" = "subdomain" ]; then
    INSTALL_COMMAND="multisite-install --subdomains"
  elif [ "${WP_TYPE}" = "subdirectory" ]; then
    INSTALL_COMMAND="multisite-install"
  else
    INSTALL_COMMAND="install"
  fi

  noroot wp core ${INSTALL_COMMAND} --url="${DOMAIN}" --quiet --title="${SITE_TITLE}" --admin_name=b2bdd --admin_email="info@b2bdd.com" --admin_password="password"

  echo "- Creating Additional Users"
  noroot wp user create "${VVV_SITE_NAME}" info@b2bdd.com --role=administrator --user_pass="password"

  echo "- Setting Permalink Structure..."
  noroot wp option update permalink_structure "/news/%postname%/"

  echo "- Setting General Settings..."
  noroot wp option update date_format "F j, Y"
  noroot wp option update timezone_string "America/New York"
  noroot wp option update gmt_offset "-5"
  noroot wp option update start_of_week "1"
  noroot wp option update time_format "g:i"
  noroot wp option update users_can_register "0"
  noroot wp option update gzipcompression "1"
  noroot wp option update WPLANG "en_US"

  echo "- Setting Reading Settings..."
  noroot wp option update blog_public "0"

  echo "- Setting Discussion Settings..."
  noroot wp option update close_comments_days_old "0"
  noroot wp option update close_comments_for_old_posts "1"
  noroot wp option update comment_moderation "1"
  noroot wp option update comment_registration "1"
  noroot wp option update default_comment_status "closed"
  noroot wp option update default_ping_status "closed"
  noroot wp option update show_avatars "0"

  echo "- Setting Media Settings..."
  noroot wp option update thumbnail_crop "0"
  noroot wp option update uploads_use_yearmonth_folders "0"

  echo "- Uninstalling and Deleting default plugins..."
  noroot wp plugin uninstall hello --deactivate
  noroot wp plugin delete hello
  noroot wp plugin uninstall akismet --deactivate
  noroot wp plugin delete akismet

  echo "- Installing and Activating plugins..."
  for plugin in "disable-comments" "tiny-compress-images" "bulk-page-creator" "tinymce-advanced" "custom-upload-dir" "google-sitemap-generator" "favicon-by-realfavicongenerator" "query-monitor" "https://github.com/wp-premium/advanced-custom-fields-pro/archive/master.zip"
    do
      noroot wp plugin install $plugin --activate
  done

else
  echo "Updating WordPress Stable..."
  cd ${VVV_PATH_TO_SITE}/htdocs
  noroot wp core update --version="${WP_VERSION}"
fi

# Create Movefile for wordmove
if [[ ! -f "${VVV_PATH_TO_SITE}/htdocs/Movefile" ]]; then
    echo "Creating Movefile..."
    cp -f "${VVV_PATH_TO_SITE}/provision/wordmove.yml" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{SITENAME}}#${VVV_SITE_NAME}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{SERVERPATH}}#${STAGING_SERVER_PATH}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{STAGEDB}}#${STAGING_DB_NAME}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{STAGEDBUSER}}#${STAGING_DB_USER}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{STAGEDBPASS}}#${STAGING_DB_PASS}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{SSHHOST}}#${STAGING_SERVER}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{SSHUSER}}#${STAGING_SERVER_USER}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
    sed -i "s#{{SSHPASSWORD}}#${STAGING_SERVER_PASS}#" "${VVV_PATH_TO_SITE}/htdocs/Movefile"
fi

cp -f "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf.tmpl" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
sed -i "s#{{DOMAINS_HERE}}#${DOMAINS}#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"

if [ -n "$(type -t is_utility_installed)" ] && [ "$(type -t is_utility_installed)" = function ] && `is_utility_installed core tls-ca`; then
    sed -i "s#{{TLS_CERT}}#ssl_certificate /vagrant/certificates/${VVV_SITE_NAME}/dev.crt;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}#ssl_certificate_key /vagrant/certificates/${VVV_SITE_NAME}/dev.key;#" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
else
    sed -i "s#{{TLS_CERT}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
    sed -i "s#{{TLS_KEY}}##" "${VVV_PATH_TO_SITE}/provision/vvv-nginx.conf"
fi
