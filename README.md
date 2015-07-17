# gringotts

![gringotts-bank](gringotts.jpg)

Personal finance manager application that gets your spending information
from various ecommerce applications (such as Amazon etc).

## Why

- Personal finance applications are bloated
- I needed automation
- Don't want to give someone access to my bank account
- Bank account statements are meaningless (not enough information)
- Most of my transactions are happening online
- Everything is tracked *somewhere*. I just needed to fetch this information

## How

- Store your credentials locally
- Run gringotts for every module to generate reports
- Reports are currently in yml format

## Modules

Currently, there are two modules:

- [splitwise](https://splitwise.com) - Expense tracker for friends, which I heavily use. Most of my shared expenses end up here
- [paytm](https://paytm.com) - This is what I use for recharges, like most of India. They do have an ecommerce store, which is also tracked

### splitwise

- Only tracks expenses where you owe something
- Tracks your share of things, instead of the whole expense
- Uses oauth

### paytm

- Tracks all orders made on paytm, including:
  + recharges
  + purchases on paytm

Does not track uber payments, because it doesn't provide enough information to be useful.

### Planned Modules

- amazon.in
- amazon.com
- flipkart
- uber

## Getting Started

This is still in alpha-quality, so no instructions as of now. I'll provide them as it gets stable.

## Inspiration

The main inspiration for this is [hinance](http://www.hinance.org/). However, I needed something more suitable to my needs (not haskell+weboob).
