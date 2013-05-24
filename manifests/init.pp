# == Class: lumberjack
#
# This class is able to install or remove lumberjack on a node.
# It manages the status of the related service.
#
# [Add description - What does this module do on a node?] FIXME/TODO
#
#
# === Parameters
#
# [*ensure*]
#   String. Controls if the managed resources shall be <tt>present</tt> or
#   <tt>absent</tt>. If set to <tt>absent</tt>:
#   * The managed software packages are being uninstalled.
#   * Any traces of the packages will be purged as good as possible. This may
#     include existing configuration files. The exact behavior is provider
#     dependent. Q.v.:
#     * Puppet type reference: {package, "purgeable"}[http://j.mp/xbxmNP]
#     * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   * System modifications (if any) will be reverted as good as possible
#     (e.g. removal of created users, services, changed log settings, ...).
#   * This is thus destructive and should be used with care.
#   Defaults to <tt>present</tt>.
#
# [*autoupgrade*]
#   Boolean. If set to <tt>true</tt>, any managed package gets upgraded
#   on each Puppet run when the package provider is able to find a newer
#   version than the present one. The exact behavior is provider dependent.
#   Q.v.:
#   * Puppet type reference: {package, "upgradeable"}[http://j.mp/xbxmNP]
#   * {Puppet's package provider source code}[http://j.mp/wtVCaL]
#   Defaults to <tt>false</tt>.
#
# [*status*]
#   String to define the status of the service. Possible values:
#   * <tt>enabled</tt>: Service is running and will be started at boot time.
#   * <tt>disabled</tt>: Service is stopped and will not be started at boot
#     time.
#   * <tt>running</tt>: Service is running but will not be started at boot time.
#     You can use this to start a service on the first Puppet run instead of
#     the system startup.
#   * <tt>unmanaged</tt>: Service will not be started at boot time and Puppet
#     does not care whether the service is running or not. For example, this may
#     be useful if a cluster management software is used to decide when to start
#     the service plus assuring it is running on the desired node.
#   Defaults to <tt>enabled</tt>. The singular form ("service") is used for the
#   sake of convenience. Of course, the defined status affects all services if
#   more than one is managed (see <tt>service.pp</tt> to check if this is the
#   case).
#
# [*version*]
#   String to set the specific version you want to install.
#   Defaults to <tt>false</tt>.
#
# [*host*]
#   Hostname to connect to
#
# [*port*]
#   Port to connect to
#
# [*files*]
#   Files to monitor
#
# [*ssl_ca*]
#   ssl CA file
#
# [*fields*]
#   extra fields to add
#
# The default values for the parameters are set in lumberjack::params. Have
# a look at the corresponding <tt>params.pp</tt> manifest file if you need more
# technical information about them.
#
#
# === Examples
#
# * Installation, make sure service is running and will be started at boot time:
#     class { 'lumberjack': }
#
# * Removal/decommissioning:
#     class { 'lumberjack':
#       ensure => 'absent',
#     }
#
# * Install everything but disable service(s) afterwards
#     class { 'lumberjack':
#       status => 'disabled',
#     }
#
#
# === Authors
#
# * Richard Pijnenburg <mailto:richard@ispavailability.com>
#
class lumberjack(
  $host,
  $port,
  $files,
  $ssl_ca_path,
  $ensure      = $lumberjack::params::ensure,
  $autoupgrade = $lumberjack::params::autoupgrade,
  $status      = $lumberjack::params::status,
  $version     = false,
  $fields      = false
) inherits lumberjack::params {

  #### Validate parameters

  # ensure
  if ! ($ensure in [ 'present', 'absent' ]) {
    fail("\"${ensure}\" is not a valid ensure parameter value")
  }

  # autoupgrade
  validate_bool($autoupgrade)

  # service status
  if ! ($status in [ 'enabled', 'disabled', 'running', 'unmanaged' ]) {
    fail("\"${status}\" is not a valid status parameter value")
  }

  validate_string($host)

  if ! is_numeric($port) {
    fail("\"${port}\" is not a valid port parameter value")
  }

  validate_array($files)
  $logfiles = join($files,' ')

  if $fields {
    validate_hash($fields)
  }

  #### Manage actions

  # package(s)
  class { 'lumberjack::package': }

  # service(s)
  class { 'lumberjack::service': }

  # file(s)
  class { 'lumberjack::config': }


  #### Manage relationships

  if $ensure == 'present' {
    # we need the software before running a service
    Class['lumberjack::package'] -> Class['lumberjack::config']

    # make sure configuration changes properly restart the daemon
    if ($status in [ 'enabled', 'running' ]) {
      Class['lumberjack::config']  ~> Class['lumberjack::service']
    } else {
      Class['lumberjack::config']  -> Class['lumberjack::service']
    }

  } else {

    # make sure all services are getting stopped before software removal
    Class['lumberjack::service'] -> Class['lumberjack::package']
  }

}
