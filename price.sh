#!/bin/bash

############################################
## Bash Simple Coin Price Checker by eth1 ##
############################################

# Verify that there was a coin entered
if [ $# -lt 1 ]; then
        echo " "
        echo "Usage: ./price [COIN] <- need caps"
        echo " "
        exit 1
fi

# Announce the start of the script

COINZ=$1

if [ ${COINZ} == "BTC" ]; then
   echo "Asking Bitstamp for Bitcoin's price"
   BITSTAMPGET=`curl -sG --max-time 15 'https://www.bitstamp.net/api/ticker/'`
   BITSTAMPPRICE=`echo $BITSTAMPGET | jq .last | cut -d '"' -f2`
   echo "["`date +%T`"]" "BTC/USD - Last: "$BITSTAMPPRICE"$ - Bitstamp"
else
# Polling these exchange prior, so we do only one pull of all the markets and parse them later on for each coin.
echo "Asking the exchanges for prices"

CRYPTSYGET=`curl -sG --max-time 60 'http://pubapi.cryptsy.com/api.php?method=marketdatav2'`
POLONIEXGET=`curl -sG --max-time 60 'https://poloniex.com/public?command=returnTicker'`
BITTREXGET=`curl -sG --max-time 60 'https://bittrex.com/api/v1.1/public/getmarketsummaries'`
ALLCOINGET=`curl -sG --max-time 60 'https://www.allcoin.com/api2/pairs'`
BLEUTRADEGET=`curl -sG --max-time 60 'https://bleutrade.com/api/v2/public/getmarketsummaries'`
CCEXGET=`curl -sG --max-time 60 'https://c-cex.com/t/prices.json'`
COINSWAPGET=`curl -sGk --max-time 60 'https://api.coin-swap.net/market/summary'`
BTERGET=`curl -sG --max-time 3 'http://data.bter.com/api/1/ticker/'$COINZ'_BTC'`

 	# Conversion functions and API commands with their parsing
	COINZLOWERCASE=`echo $COINZ | awk '{print tolower($0)}'`

	# BTER Api Parsing
	BTERPRICE=`echo $BTERGET | sed '/^$/d' | cut -d, -f2 | cut -d ":" -f2`  

	# CRYPTSY API parsing
	CRYPTSYPRICE=`echo $CRYPTSYGET | jq --arg cur "$COINZ" '.return.markets."\($cur)/BTC".lasttradeprice' | cut -d '"' -f2`

	# Mintpal being broken by Moolah the cunt, we have to disable it
	MINTPALPRICE="null"
	#MINTPALPRICE=`echo $MINTPALGET | jq -r .[].last_price`

	POLONIEXPRICE=`echo $POLONIEXGET | jq -r .BTC_$COINZ.last`

	# Bittrex API Needs to convert scientific notation numbers to decimals
	BITTREXPRICERAW=`echo $BITTREXGET | jq --arg cur "$COINZ" '.result[] | select(.MarketName == "BTC-\($cur)").Last'`
	BITTREXPRICE=`echo $BITTREXPRICERAW | awk '{ print sprintf("%.8f", $1); }'`

	# C-CEX Price Parsing
	CCEXPRICE=`echo $CCEXGET | jq --arg cur "$COINZLOWERCASE" '."\($cur)-btc".lastprice'`

	# BLEUTRADE Price Parsing
	BLEUTRADEPRICE=`echo $BLEUTRADEGET | jq --arg cur "$COINZ" '.result[] | select(.MarketName == "\($cur)_BTC").Last' | cut -d '"' -f2`

	# COINSWAP Price Parsing
	COINSWAPPRICE=`echo $COINSWAPGET | jq --arg cur "$COINZ" '.[] | select(.symbol == "\($cur)") | select(.exchange == "BTC").lastprice' | cut -d '"' -f2`

	# ALLCOIN Price Parsing
	ALLCOINPRICE=`echo $ALLCOINGET | jq --arg cur "$COINZ" '.data."\($cur)_BTC".trade_price' | cut -d '"' -f2`

	# Conditions of acceptance; write to the database and logfile. If null, pass on.

        if [ "${MINTPALPRICE}" != "null" ]; then 
	       MINTPALLOW=`echo $MINTPALGET | cut -d, -f9 | cut -d '"' -f4`
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$MINTPALPRICE" - Low: "$MINTPALLOW" - Mintpal"
        fi   

        if [ "${CRYPTSYPRICE}" != "null" ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$CRYPTSYPRICE" - Cryptsy"
        fi   

        if [ "${POLONIEXPRICE}" != "null" ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$POLONIEXPRICE" - Poloniex"
        fi   

        if [ "${BITTREXPRICE}" != "" ]; then
	   if [ "${BITTREXPRICE}" == "0.00000000" ]; then 
       	       BITTREXPRICE="null" 
	   else
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$BITTREXPRICE" - Bittrex"
	   fi	
        fi   

	if [ "${CCEXPRICE}" != "" ]; then 
	echo $CCEXPRICE | grep -E '^-?[0-9]*\.?[0-9]*$' > /dev/null
	if [ $? -eq 0 ]; then 
	       
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$CCEXPRICE" - C-CEX"
        fi   
	fi

        if [ "${BLEUTRADEPRICE}" != "" ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$BLEUTRADEPRICE" - Bleutrade"

        fi   

        if [ "${COINSWAPPRICE}" != "" ]; then 
        echo $COINSWAPPRICE | grep -E '^-?[0-9]*\.?[0-9]*$' > /dev/null
        if [ $? -eq 0 ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$COINSWAPPRICE" - Coin-Swap"

        fi   
	fi

        if [ "${ALLCOINPRICE}" != "" ]; then 
        echo $ALLCOINPRICE | grep -E '^-?[0-9]*\.?[0-9]*$' > /dev/null
        if [ $? -eq 0 ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$ALLCOINPRICE" - Allcoin"
        fi   
	fi

        if [ "${BTERPRICE}" != "" ]; then 
        echo $BTERPRICE | grep -E '^-?[0-9]*\.?[0-9]*$' > /dev/null
        if [ $? -eq 0 ]; then 
               echo "["`date +%T`"]" $COINZ"/BTC - Last: "$BTERPRICE" - BTER"

        fi   
	fi

fi
### END OF THE MAGIC --- coded by eth1
