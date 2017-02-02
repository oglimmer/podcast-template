<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the
 * installation. You don't have to use the web site, you can
 * copy this file to "wp-config.php" and fill in the values.
 *
 * This file contains the following configurations:
 *
 * * MySQL settings
 * * Secret keys
 * * Database table prefix
 * * ABSPATH
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
#define('DB_NAME', 'wordpress_prod');

/** MySQL database username */
#define('DB_USER', 'usr_wordpress_prod');

/** MySQL database password */
#define('DB_PASSWORD', '.....');

/** MySQL hostname */
#define('DB_HOST', 'localhost');

/** Database Charset to use in creating database tables. */
define('DB_CHARSET', 'utf8mb4');

/** The Database Collate type. Don't change this if in doubt. */
define('DB_COLLATE', '');

/**#@+
 * Authentication Unique Keys and Salts.
 *
 * Change these to different unique phrases!
 * You can generate these using the {@link https://api.wordpress.org/secret-key/1.1/salt/ WordPress.org secret-key service}
 * You can change these at any point in time to invalidate all existing cookies. This will force all users to have to log in again.
 *
 * @since 2.6.0
 */
define('AUTH_KEY',         '&r2sfu6:+|O96=bvo8[|gd29}>KUrw_+sRkJpP3,@64Uq@+,>d`iR3;*}n)[vU~<');
define('SECURE_AUTH_KEY',  ')ubDK|h6w,P)!8g`#CSn(e)rvw`[|il^(D9%%tcrL,o}q@S-n=n14O)P]NP_+QIc');
define('LOGGED_IN_KEY',    'k:-=BI;.<&t*|*>k|[#S<vq|F-?B4.NRIwv,vL87:YK`E%PP@|Y*.B0LWYU3[0;V');
define('NONCE_KEY',        'M|$osB<4ECRO6NV!921.Ea$wgcQ_]}Imra@e(7NP|43;#<zwZ$ds:qqicLP_^!%+');
define('AUTH_SALT',        '_T1O%>Ss,yPW,-Q,)@/sG|fF!V*5qnU>NfF/6gW=|]?A.zr%s*MZT] y0,XjHX`[');
define('SECURE_AUTH_SALT', 'c:?H@]CSwj( #|$ZE|r69cr(q=-]UVNzB6]p(gVH{]Qs@HAn6cR-i-32T^0[ x45');
define('LOGGED_IN_SALT',   'QyQ-6]]<F}fHHYY+#r+FkV=0RK!?OJO+jP=Udn6E ;KWi#qYdRjMfd7&dD=YY0Wk');
define('NONCE_SALT',       'K}_ +(6|^jH>*g 2l@[d?-o{0rkJ0p1^6jvqh]b9Up~&k<hv1.nf<h*-<[6S+W-(');

/**#@-*/

/**
 * WordPress Database Table prefix.
 *
 * You can have multiple installations in one database if you give each
 * a unique prefix. Only numbers, letters, and underscores please!
 */
$table_prefix  = 'wp_prod_';

/**
 * ADDED BY OZ
 *
 */
include("/etc/wordpress/config-default.php");

/**
 * For developers: WordPress debugging mode.
 *
 * Change this to true to enable the display of notices during development.
 * It is strongly recommended that plugin and theme developers use WP_DEBUG
 * in their development environments.
 *
 * For information on other constants that can be used for debugging,
 * visit the Codex.
 *
 * @link https://codex.wordpress.org/Debugging_in_WordPress
 */
define('WP_DEBUG', false);

/* That's all, stop editing! Happy blogging. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');

//** Error Logging aktiviert, 14.01.17 TH */
ini_set('log_errors', 'On');
ini_set('error_log', '/var/log/apache2/php-errors.log');

?>
