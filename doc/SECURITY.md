Security
========

This document is intended to help our customers'
security, risk, and compliance folks
evaluate what we do with our customers' code and data.

Because [Hound is open source][oss],
in this document we refer to portions of the application code and its dependent
libraries, frameworks, and programming languages.
We hope this makes it easier for developers to evaluate our security measures.

[oss]: https://github.com/thoughtbot/hound

Vulnerability Reporting
-----------------------

For security inquiries or vulnerability reports, please email
[security@thoughtbot.com](security@thoughtbot.com).
If you'd like, you can use our [PGP key] when reporting vulnerabilities.

[PGP key]: http://pgp.thoughtbot.com

thoughtbot
----------

Hound is operated by [thoughtbot, inc.], a [Massachusetts corporation][sec].

[thoughtbot, inc.]: http://thoughtbot.com
[sec]: http://corp.sec.state.ma.us/CorpWeb/CorpSearch/CorpSummary.aspx?FEIN=203438204

A small team within thoughtbot is responsible for Hound.

What happens when you authenticate your GitHub account
------------------------------------------------------

Hound uses the [OmniAuth GitHub] Ruby gem to
authenticate your GitHub account using [GitHub's OAuth2 flow][gh-oauth].

[OmniAuth GitHub]: https://github.com/intridea/omniauth-github
[gh-oauth]: https://developer.github.com/v3/oauth/

Using OAuth2 means we do not access your GitHub password
and that you can revoke our access at any time.

We store a GitHub token in your web browser's session cookie.
We do not store this GitHub token in our PostgreSQL database.

We need this cookie in order to refresh your GitHub repositories with Hound,
which we do once, immediately after you authenticate your GitHub account.
Later, you can manually refresh your GitHub repositories with Hound at any time.

To browse the portions of the codebase related to authentication,
try `grep`ing for the following terms:

```bash
grep -R omniauth app
grep -R github_token app
```

What happens when Hound refreshes your GitHub repositories
----------------------------------------------------------

We pass your GitHub token to our [Ruby on Rails] app
(the app whose source code you are reading right now),
which runs on [Heroku].

[Ruby on Rails]: http://rubyonrails.org
[Heroku]: https://www.heroku.com

Heroku is a "Platform as a Service",
which runs on Amazon Web Services' "Infrastructure as a Service."
Read [Heroku's security policy][aws] for information about their
security assessments, compliance, penetration testing,
environmental safeguards, network security, and more.

[aws]: https://www.heroku.com/policy/security

Our Ruby process passes your GitHub token from memory to our [Redis] database
The database is hosted by [Redis to Go],
which is owned by [Rackspace].

[Redis]: http://redis.io/
[Redis to Go]: http://redistogo.com
[Rackspace]: http://www.rackspace.com/

This allows you to later "enable" Hound on GitHub repos.

What happens when you "enable" Hound on your GitHub repository
--------------------------------------------------------------

When you click the "toggle" switch in the Hound web interface
for one of your private GitHub repositories,
we send your GitHub token from the web browser's session
to the Ruby process on Heroku
through the [`SubscriptionsController`].

[`SubscriptionsController`]: ../app/controllers/subscriptions_controller.rb

We use your GitHub token to add the @houndci GitHub user to your repository
via the [GitHub collaborator API][api1].
Your GitHub user will need admin privileges for that repository.

[@houndci]: https://github.com/houndci
[api1]: https://developer.github.com/v3/repos/collaborators/#add-collaborator

We create a webhook on your repository via the [GitHub webhook API][api2].
This allows us to later receive your commits and pull requests.

[api2]: https://developer.github.com/v3/repos/hooks/#create-a-hook

To browse the portions of the codebase related to enabling repos,
try `grep`ing for the following terms:

```bash
grep -R add_hound_to_repo app
grep -R create_webhook app
```


What happens when you pay for Hound
-----------------------------------

The first time you enable a private GitHub repo with Hound,
we use [Stripe Checkout] to collect and send your credit card information
to [Stripe], a payment processor.

Your credit card data is sent directly from your web browser to Stripe
over a TLS connection.
It is never sent through Hound's Ruby processes
and we never store your credit card information.

[Stripe Checkout]: https://stripe.com/checkout
[Stripe]: https://stripe.com

We receive a token from Stripe that represents a unique reference to your
credit card within the context of Hound's application.

Read [Stripe's security policy] for information about PCI compliance,
TLS, encryption, and more.

[Stripe's security policy]: https://stripe.com/help/security

To browse the portions of the codebase related to payment,
try `grep`ing for the following terms:

```bash
grep -R card_token app
grep -R stripe_customer app
```

What happens when we receive a GitHub build notification
--------------------------------------------------------

TODO

Employee access
---------------

TODO

What you can do to make your Hound experience safer
---------------------------------------------------

[GitHub two-factor authentication][two-factor]

[two-factor]: https://help.github.com/articles/about-two-factor-authentication/

12-factor, environment variables

http://12factor.net/
http://12factor.net/config

Third-party auditing
--------------------

We can't afford it, but the codebase is open-source. Believe in transparency.
Audits only look at codebase at a given point in time (snapshot). Code would be
"out of compliance" within a day or two given how frequently we push to repo.
