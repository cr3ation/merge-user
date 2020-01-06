# Merge User
> Merge users in macOS.

In event of user changes ID (happily married) macOS will create a new local user – rendering user unable to access its Documents, Keychain, FileVault, settings etc.

  Merge User lets you merge one users Name and Home Directory to another while keeping the original User ID, adding the new User ID as an alias.

![](Tutorial/merge-user-interface.png)

## Installation

macOS:

Open in Xcode and build.

## Usage example

1) Start _Merge User.app_
2) Current logged in user is automatically selected.
3) Use dropdown to select user you want to merge to (get it's files)
4) Start migration, enter password.
5) Reboot

_For more examples and usage, please refer to the [Wiki][wiki]._

## Release History

* 0.3.0
    * CHANGE: Moved to Git
* 0.2.9
    * CHANGE: Renamed to `Migrate User`
* 0.0.1
    * Work in progress

## Meta

Henrik Engström – me@henrikengstrom.com

Distributed under the GNU General Public License v3.0 license. See ``LICENSE`` for more information.

[https://github.com/cr3ation/merge-user](https://github.com/cr3ation)

## Contributing

1. Fork it (<https://github.com/cr3ation/merge-user/fork>)
2. Create your feature branch (`git checkout -b feature/fooBar`)
3. Commit your changes (`git commit -am 'Add some fooBar'`)
4. Push to the branch (`git push origin feature/fooBar`)
5. Create a new Pull Request

<!-- Markdown link & img dfn's -->
[travis-image]: https://img.shields.io/travis/dbader/node-datadog-metrics/master.svg?style=flat-square
[travis-url]: https://travis-ci.org/dbader/node-datadog-metrics
[wiki]: https://github.com/cr3ation/merge-user/wiki
