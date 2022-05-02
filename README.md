# Speakap

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'speakap'
```

To make an api:

```
speakap = Speakap::Api.new(speakap_network_eid, speakap_app_id, speakap_secret_key)
```

Send a notification by xid:

```
create_notification_by_xid("1234", "You've got a message","extadata")
```

Get a user by EID:

```
get_user_by_eid(eid)
```

Get all users, Permission `get_user_groups` is required.

```
get_users
```

Import all users
```
rake speakap_users:import
```
