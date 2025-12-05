#!/bin/bash

ln -sf /etc/freeradius/sites-available/default /etc/freeradius/sites-enabled/default
ln -sf /etc/freeradius/sites-available/inner-tunnel /etc/freeradius/sites-enabled/inner-tunnel

exec "$@"
