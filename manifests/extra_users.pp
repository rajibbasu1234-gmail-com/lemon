# Allow cheroux to access lemon servers
class s_lemon::extra_users inherits user::virtual {
  realize User['cheroux']
}
