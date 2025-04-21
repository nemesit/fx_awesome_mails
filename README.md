### FXAwesomeMails
Provides various view helpers for cross client mail creation.
FX Awesome Mails is a Ruby gem for generating table-based HTML emails within Rails applications.
It provides a SwiftUI inspired dsl for

#### Installation
Add this line to your application's Gemfile:

```ruby
gem 'fx_awesome_mails'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install fx_awesome_mails
```

#### Usage

Below is a quick reference for the main components:

- **fx.preheader** – Creates content for the preview area of email clients.
  `<%= fx.preheader "Preview Content" %>`
  or alternatively
  ```
    <%= fx.preheader do %>
      some content
    <% end %>
  ```
- **fx.email_container** – Generates the main container table that centers your email content. (Renamed from content_table for clarity.)
- **fx.hstack** – Creates a horizontal row container.
- **fx.vstack** – Creates a vertical stack for content.
- **fx.spacer** – Inserts an element with configurable spacing (size, color, and CSS options).
- **fx.titlebar_link** – Renders a link styled as a title bar.
- **fx.image** – Displays an image with optional link target.
- **fx.divider** – Adds a divider line.
- **fx.text** – Outputs text content with CSS options.
- **fx.item** – wraps individual stack items in the required html nodes


