<?php
// https://wordpress.stackexchange.com/questions/100234/wp-cli-displays-php-notices-when-display-errors-off
// https://developer.wordpress.org/cli/commands/core/version/

error_reporting(0); @ini_set('display_errors', 0);
