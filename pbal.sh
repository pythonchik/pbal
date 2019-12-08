#!/bin/bash

#set -x

#ERR_NEED_TWO_PARAMS="need two params"
#USER_AGENT='Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:5.0.1) Gecko/20100101 Firefox/5.0.1'
#USER_AGENT="Mozilla/5.0 (Macintosh; Intel Mac OS X 1084) AppleWebKit/536.28.10 (KHTML like Gecko) Version/6.0.3 Safari/536.28.10"
USER_AGENT="Mozilla/4.0"
TIME_OUT=120
ATTEMPTS=1
ATTEMPTS_TIME_OUT=30
SILENT=0
VERBOSE=0
SHOW_ACC=0

function resp {
	if [ -r $1 ]; then
		status_code=`head -n1 $1 | cut -d' ' -f2`
		if [ "$status_code" == "302" ] || [ "$status_code" == "301" ] || [ "$status_code" == "100" ]; then # may be it's header like cookie
			status_code_new=`grep -e "^HTTP" $1 | tail -n1 | cut -d' ' -f2`
			if [ -n "$status_code_new" ]; then 
				echo $status_code_new
			else
				echo $status_code
			fi
		else
			echo $status_code
		fi
	else
		echo 999
	fi
}

function err {
	if [ $SILENT -eq 0 ]; then
		if [ $VERBOSE -eq 0 ]; then
			echo "ERROR: $1"
		else
			echo "$voperator $vlogin ERROR: $1"
		fi
	fi
	rm -f $tmp_cookie
	rm -f $tmp_file
	exit 1
}

function err404 {
	err "Page $1 has been change own structure"
}

function err999 {
	err "Connection error or can't write to /tmp"
}

function errATT {
	err "Exceeded the number of connection attempts to the server"
}

function errCOO {
	err "Can't get cookies from $1 or can't write to /tmp"
}

##### CUT HERE #####

function megafon {
	tmp_file=/tmp/megafon.response

	rv=0
	i=0
	page="http://sg.megafon.ru/ps/scc/php/route.php"
	while [ "$rv" != "200" ]; do
		curl -i -s -m $TIME_OUT $page \
            -d "CHANNEL=WWW&ULOGIN=$1" > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	 
	done


    url=`sed -n -e 's/<URL>\(.*\)<\/URL>/\1/p' $tmp_file`

	if [ -z "$url" ]; then
		err "Can't get service-guide url from $page"
	fi
	
	rv=0
	i=0
	page=$url"ROBOTS/SC_TRAY_INFO?X_Username=$1&X_Password=$2"
	while [ "$rv" != "200" ]; do
		curl -L -i -s -m $TIME_OUT $page \
			| iconv -c -fcp1251 > $tmp_file
	
		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	 
	done

    errmsg=`sed -ne 's/<MSEC-COMMAND>\(.*\)<\/MSEC-COMMAND>/\1/p' $tmp_file`
    if [ -n "$errmsg" ]; then
        err "$errmsg"
    fi

	balance=`sed -ne 's/<BALANCE>\(.*\)<\/BALANCE>/\1/p' $tmp_file`

	rm $tmp_file

    if [ -z "$balance" ]; then
        err "Can't get balance. Unkonown error."
    fi
	
	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo megafon $1 $balance
	fi
}

function corbina {
	tmp_file=/tmp/corbina.response
	tmp_cookie=/tmp/corbina.cookies

	rv=0
	i=0
	page="https://lk.beeline.ru/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")
		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	rv=0
	i=0
	page="https://lk.beeline.ru/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT -L "$page" \
			-c $tmp_cookie \
			-b $tmp_cookie \
            -d "login=$1&password=$2" \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	balance=`grep "Баланс:" $tmp_file | sed -n -e 's/.*>\([0-9]*.[0-9][0-9]\).*/\1/p'`

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo corbina $1 $balance
	fi

	rm -f $tmp_cookie
    rm -f $tmp_file

}

function mts {
	tmp_file=/tmp/mts.response
	tmp_cookie=/tmp/mts.cookies

	rv=0
	i=0
	page="https://login.mts.ru/amserver/UI/Login?service=lk&goto=https://lk.ssl.mts.ru/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")
		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

    CSRFToken=`grep CSRFToken $tmp_file | sed -n -e 's/.*value="\(.*\)".*/\1/p'|head -n1`

    if [ -z "$CSRFToken" ]; then
        err "Can't get CSRFToken from $page"
    fi

	rv=0
	i=0
	
	tmp_file=/tmp/mts.response1
	page="https://login.mts.ru/amserver/UI/Login?service=lk&goto=https://lk.ssl.mts.ru/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			-b $tmp_cookie \
            -d "IDToken1=$1&IDToken2=$2&goto=https%3A%2F%2Flk.ssl.mts.ru%2F&encoded=false&loginURL=%2Fservice%3Dlk%26gx_charset%3DUTF-8%26goto%3Dhttps%253A%252F%252Flk.ssl.mts.ru%252F&CSRFToken=$CSRFToken" \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

    errmsg=`grep small $tmp_file | sed -n -e 's/.*<small>\(.*\)<\/small>.*/\1/p'`
    if [ -n "$errmsg" ]; then
        err "$errmsg"
    fi

    #errmsg=`grep 'label validate="IDToken2"' $tmp_file | sed -n -e 's/.*<label.*>\(.*\)<\/label>.*/\1/p'`
    errmsg=`grep "label validate" $tmp_file | sed -n -e 's/.*<label.*>\(.*\)<\/label>/\1/p' | sed -e 's/^[ \t]*//' | tr -d '\n'`
    if [ -n "$errmsg" ]; then
        err "$errmsg"
    fi

	rv=0
	i=0
	#page="https://login.mts.ru/profile/mobile/get"
	#page="https://ihelper.mts.ru/selfcare/Services/get-balance.ashx?update=0"
    #page="https://ihelper.mts.ru/selfcare/account-status.aspx"
    
    tmp_file=/tmp/mts.response2

    page="https://login.mts.ru/profile/header?service=lk&style=2013&update"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -m $TIME_OUT "$page" \
            -c $tmp_cookie \
			-b $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file
		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done
	
	#balance=`sed -n -e 's/.*balance":"\(.*\)","tariff.*/\1/p' $tmp_file`
	#balance=`sed -n -e 's/.*<strong>\(.*\) .*<\/strong>.*/\1/p' $tmp_file`
    balance=`grep "Ваш баланс" $tmp_file | sed -n -e 's/.*>\(.*\)<\/a><a.*/\1/p' | cut -d' ' -f1`

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo mts $1 $balance
	fi

	rm -f $tmp_cookie
    #rm -f $tmp_file
}

function mts_pda {
	tmp_file=/tmp/mts.response
	tmp_cookie=/tmp/mts.cookies

	rv=0
	i=0
	
	page="https://ip.mts.ru/selfcarepda/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")
		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

    # Пока проверка токеан не нужна

    #CSRFToken=`grep CSRFToken $tmp_file | sed -n -e 's/.*value="\(.*\)".*/\1/p'|head -n1`
    #if [ -z "$CSRFToken" ]; then
    #    err "Can't get CSRFToken from $page"
    #fi

	rv=0
	i=0
	
	page="https://ihelper.nw.mts.ru/SELFCAREPDA/Security.mvc/LogOn"
	
	tmp_file=/tmp/mts.response1

	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			-b $tmp_cookie \
            -d "returnLink=http%3A%2F%2Fip.mts.ru%3A8085%2FSELFCAREPDA%2FHome.mvc&username=$1&password=$2" \
            --user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

    # Проверку на ошибку сделаем потом - надо моделировать ошибки
	
	#errmsg=`grep small $tmp_file | sed -n -e 's/.*<small>\(.*\)<\/small>.*/\1/p'`
    #if [ -n "$errmsg" ]; then
    #    err "$errmsg"
    #fi

    #errmsg=`grep 'label validate="IDToken2"' $tmp_file | sed -n -e 's/.*<label.*>\(.*\)<\/label>.*/\1/p'`
    #errmsg=`grep "label validate" $tmp_file | sed -n -e 's/.*<label.*>\(.*\)<\/label>/\1/p' | sed -e 's/^[ \t]*//' | tr -d '\n'`
    #if [ -n "$errmsg" ]; then
    #    err "$errmsg"
    #fi

	rv=0
	i=0

    ## Выбираем строку со словом Баланс
    ## Обрезаем регуляркой
    ## пробуем убрать лишние пробелы
    ## заменяем запятую на точку, чтобы преобразование к числу прошло ОК
    balance=`grep "Баланс: " $tmp_file | sed -n -e 's/.*strong>\(.*\) (руб.)<\/strong>.*/\1/p'| cut -d' ' -f1|sed 's/,/./g'`

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo mts $1 $balance
	fi

	rm -f $tmp_cookie
    #rm -f $tmp_file
}

function intertelecom_ua_old {
	tmp_file=/tmp/intertelecom_ua.response
	tmp_cookie=/tmp/intertelecom_ua.cookies

	rv=0
	i=0
	page="https://assa.intertelecom.ua/ru/login/"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")
		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	rv=0
	i=0
	
	page="https://assa.intertelecom.ua/ru/login/"
	
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			-b $tmp_cookie \
            -d "phone=$1&pass=$2&js=1" \
            --user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	errmsg=`grep -E "\"error\">(.*)" $tmp_file | sed -n -e 's/.*<p class="error">\(.*\)<\/p>.*/\1/p'`
    if [ -n "$errmsg" ]; then
       err "$errmsg"
    fi
  
	rv=0
	i=0

    ## Выбираем строку со словом Сальдо
    ## Обрезаем регуляркой
    ## пробуем убрать лишние пробелы
    ## заменяем запятую на точку, чтобы преобразование к числу прошло ОК
    balance=`grep -A 2 -E ".*<td>Сальдо</td>.*" $tmp_file | tail -n 1 | awk '{print $1}'`

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo intertelecom_ua $1 $balance
	fi

	rm -f $tmp_cookie
    rm -f $tmp_file
}

function intertelecom_ua {
	tmp_file=/tmp/intertelecom_ua.response
	tmp_cookie=/tmp/intertelecom_ua.cookies

	rv=0
	i=0
	page="https://services.intertelecom.ua/login/?lang=ru"
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")
		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	form_id=`cat /tmp/intertelecom_ua.response | grep "form_id" |tail -n 1|tr "=\"" "\n"|tail -n 2|head -n 1`
	rv=0
	i=0
	
	page="https://services.intertelecom.ua/login/password/"
	
	while [ "$rv" != "200" ]; do
		curl -i -k -L -s -m $TIME_OUT "$page" \
			-c $tmp_cookie \
			-b $tmp_cookie \
            -X POST \
            -F "action=ongoing_password_check" \
            -F "form_id=$form_id" \
            -F "lang=ru" \
            -F "back_page=" \
            -F "subscriber_number$form_id=$1" \
            -F "ongoing_password$form_id=$2" \
            --user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	

	done

	errmsg=`grep -E "\"error\">(.*)" $tmp_file | sed -n -e 's/.*<p class="error">\(.*\)<\/p>.*/\1/p'`
    if [ -n "$errmsg" ]; then
       err "$errmsg"
    fi
  
	rv=0
	i=0

    ## Выбираем строку со словом Сальдо
    ## Обрезаем регуляркой
    ## пробуем убрать лишние пробелы
    ## заменяем запятую на точку, чтобы преобразование к числу прошло ОК
    # balance=`grep -A 2 -E ".*<td>Сальдо</td>.*" $tmp_file | tail -n 1 | awk '{print $1}'`
	balance=`grep "account_balance =" $tmp_file | head -n1 | cut -d'=' -f2 |cut -d',' -f1| cut -d' ' -f2`

	nnn=`cat $tmp_file | grep -n "thumbnail" | head -n1| cut -d':' -f1`
	acc=`cat $tmp_file | tail -n +$nnn | head -n7 | tail -n1 | awk '{split($0,a,","); print a[1]}'|cut -d'>' -f2`


	if [ $VERBOSE -eq 0 ]; then
		if [ $SHOW_ACC -eq 0 ]; then
			echo $balance
		else
			echo $balance $acc
		fi
	else
		if [ $SHOW_ACC -eq 0 ]; then
			echo intertelecom_ua $1 $balance
		else
			echo intertelecom_ua $1 $balance $acc
		fi
	fi

	rm -f $tmp_cookie
    rm -f $tmp_file

}

function beeline {
	tmp_file=/tmp/beeline.response
	tmp_cookie=/tmp/beeline.cookies

	rv=0
	i=0
	page="https://uslugi.beeline.ru/loginPage.do"
	while [ "$rv" != "200" ]; do
		curl -i -s -m $TIME_OUT -L -c $tmp_cookie $page \
			-d "_stateParam=eCareLocale.currentLocale%3Dru_RU__Russian&_forwardName=null&_resetBreadCrumbs=false&_expandStatus=&userName=$1&password=$2&ecareAction=login" \
			--referer "https://uslugi.beeline.ru/vip/loginPage.jsp" \
			--user-agent $USER_AGENT | iconv -c -fcp1251 > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	if [ ! -r "$tmp_cookie" ]; then
		errCOO "$page"
	fi

	errmsg=`grep "Ошибка\!" $tmp_file | awk -F "</b> " '{print $2}'`
	
	if [ -n "$errmsg" ]; then
		err $errmsg
	fi

	rv=0
	i=0
	page="https://uslugi.beeline.ru/vip/prepaid/refreshedPrepaidBalance.jsp"
	while [ "$rv" != "200" ]; do
		curl -i -s -m $TIME_OUT -L -c $tmp_cookie -b $tmp_cookie $page | iconv -c -fcp1251 > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	balance=`grep small $tmp_file \
			| sed 's/&nbsp;/ /g' \
			| cut -d " " -f 1 \
			| sed -e 's/^[ \t]*//' \
			| sed s/,/./g`
    
    if [ -z "$balance" ]; then
        err "Can't get balance"
    fi

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo beeline $1 $balance
	fi

	rm -f $tmp_cookie
    rm -f $tmp_file
}

function onlime {
	tmp_file=/tmp/onlime.response
	tmp_cookie=/tmp/onlime.cookies

	rv=0
	i=0
	page="https://my.onlime.ru"
	while [ "$rv" != "200" ]; do
		curl -k -i -s -m $TIME_OUT -c $tmp_cookie $page > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	if [ ! -r "$tmp_cookie" ]; then
		errCOO "$page"
	fi

	rv=0
	i=0
	page="https://my.onlime.ru/session/login"
	while [ "$rv" != "200" ]; do
		curl -k -i -s -m $TIME_OUT -L \
			-b $tmp_cookie \
			-c $tmp_cookie \
			-d "login_credentials%5Blogin%5D=$1&login_credentials%5Bpassword%5D=$2&commit=%D0%92%D0%BE%D0%B9%D1%82%D0%B8" $page > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	errmsg=`grep "<title>ERROR</title>" $tmp_file | sed -n -e "s/.*<h1>\(.*\)<\/h1>.*/\1/p"`
	if [ -n "$errmsg" ]; then
		err "$errmsg"
	fi

	errmsg=`grep err_msg_password $tmp_file | sed -n -e "s/.*<br>\(.*\)<br>.*/\1/p"`
	if [ -n "$errmsg" ]; then
		err "$errmsg"
	fi

    rv=0
    i=0
    page="https://my.onlime.ru/json/cabinet/"
    while [ "$rv" != "200" ]; do
        curl -k -i -s -m $TIME_OUT -L \
            -b $tmp_cookie \
            -c $tmp_cookie \
            $page > $tmp_file

        rv=$(resp "$tmp_file")

        if [ "$rv" != "200" ]; then
            case "$rv" in
                "999")
                    err999
                    ;;
                "404")
                    err404 "$page"
                    ;;
                *)
                    sleep $ATTEMPTS_TIME_OUT
                    let i=i+1
                    ;;
            esac
        fi

        if [ "$rv" == "200" ]; then
            #balance=`sed -n 's/.*\"balance\":\(.*\),\"lock\".*/\1/p' $tmp_file`
            balance=`grep -o 'balance":[0-9]*.[0-9]*' $tmp_file | cut -d':' -f2`
            if [ ! -n "$balance" ]; then
                rv=500
                let i=i+1
                #exit 1
            fi
        fi

        if [ $i -ge $ATTEMPTS ]; then
            errATT
        fi
    done

	#balance=`sed -n -e "s/.*<big>\(.*\)<\/big>.*/\1/p" $tmp_file \
	#	| grep -v strong \
	#	| head -n1`

    #balance=`sed -n 's/.*\"balance\":\(.*\),\"lock\".*/\1/p' $tmp_file`
    balance=`grep -o 'balance":[0-9]*.[0-9]*' $tmp_file | cut -d':' -f2`

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo onlime $1 $balance
	fi

	rm -f $tmp_cookie
    rm -f $tmp_file
}

function qiwi {
    tmp_file=/tmp/qiwi.response
    tmp_cookie=/tmp/qiwi.cookies

    rv=0
    i=0
    page="https://w.qiwi.com/auth/login.action"
    while [ "$rv" != "200" ]; do
        curl -i -s -m $TIME_OUT -c $tmp_cookie --get -d "source=MENU" --data-urlencode "login=$1" --data-urlencode "password=$2" $page > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	errmsg=`grep -v NORMAL $tmp_file | sed -n -e 's/.*message":"\(.*\)",".*/\1/p'`
	if [ -n "$errmsg" ]; then
		err "$errmsg"
	fi
	
	rv=0
	i=0
	page="https://w.qiwi.com/user/person/account/list.action"
	while [ "$rv" != "200" ]; do
		curl -i -s -m $TIME_OUT -b $tmp_cookie  $page \
			--referer "https://w.qiwi.com/person/account/main.action" > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	balance=`grep balance $tmp_file \
        | head -n2 \
        | tail -n1 \
        | sed 's/[^0-9,-]*//g' \
        | sed "s/,/\./g"`

	rm -f $tmp_cookie
    rm -f $tmp_file

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo qiwi $1 $balance
	fi
}

function mgts {
	tmp_file=/tmp/mgts.response
	tmp_cookie=/tmp/mgts.cookies

	rv=0
	i=0
	page="https://ihelper.mgts.ru/CustomerSelfCare2/logon.aspx"
	while [ "$rv" != "200" ]; do
		curl -k -i -s -m $TIME_OUT -c $tmp_cookie $page > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	viewstate=`grep VIEWSTATE $tmp_file | sed -n -e 's/.*value="\(.*\)".*/\1/p'`
	if [ -z "$viewstate" ]; then
		err "Can't get VIEWSTATE__ from $page"
	fi
	
	rv=0
	i=0
	page="https://ihelper.mgts.ru/CustomerSelfCare2/logon.aspx"
	while [ "$rv" != "200" ]; do
		curl -k -L -i -s -m $TIME_OUT -c $tmp_cookie -b $tmp_cookie $page \
			--data-urlencode "__VIEWSTATE=$viewstate" \
			-d "ctl00%24MainContent%24tbPhoneNumber=$1" \
			-d "ctl00%24MainContent%24tbPassword=$2" \
			-d "ctl00%24MainContent%24btnEnter=%D0%92%D0%BE%D0%B9%D1%82%D0%B8+%3E" \
			--referer "$page" \
			--user-agent $USER_AGENT > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	errmsg=`grep "b_error" $tmp_file | grep -v "%CONTENT%" | sed -n -e 's/.*<div\ class="bln">\(.*\)<\/div><div\ class="lbottom">.*/\1/p'`
	if [ -n "$errmsg" ]; then
		err "$errmsg"
	fi
	
	rv=0
	i=0
	page="https://ihelper.mgts.ru/CustomerSelfCare2/account.aspx"
	while [ "$rv" != "200" ]; do
		curl -k -i -s -m $TIME_OUT -c $tmp_cookie -b $tmp_cookie $page \
			--referer "https://ihelper.mgts.ru/CustomerSelfCare2/logon.aspx" > $tmp_file

		rv=$(resp "$tmp_file")

		if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

	balance=`sed -n -e 's/.*<strong class="balance-value">\(.*\)<\/strong><\/strong>.*/\1/p' $tmp_file \
        | sed 's/[^0-9,-]*//g' | sed "s/,/\./g"`

	rm -f $tmp_cookie
    rm -f $tmp_file

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo mgts $1 $balance
	fi
}

function kyivstar {
    tmp_file=/tmp/kyivstar.response
    tmp_cookie=/tmp/kyivstar.cookies

    rv=0
    i=0
    page='https://my.kyivstar.ua/tbmb/login/show.do'
    while [ "$rv" != "200" ]; do
       curl -k -i -s -L -m $TIME_OUT "$page" | iconv -c -f cp1251 > $tmp_file 

       rv=$(resp "$tmp_file")

       if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

    rv=0
    i=0
    page='https://my.kyivstar.ua'`grep loginForm $tmp_file | sed -n 's/.*action="\(.*\)" onsubmit=.*/\1/p'`
    while [ "$rv" != "200" ]; do
       curl -k -i -s -L -m $TIME_OUT "$page" \
       --data-urlencode "user=$1" \
       --data-urlencode "password=$2" \
       | iconv -c -f cp1251 > $tmp_file 

       rv=$(resp "$tmp_file")

       if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

    errmsg=`cat $tmp_file \
        | grep redError \
        | grep '<td' \
        | sed -n -e 's/.*<td.*>\(.*\)<\/td>.*/\1/p' \
        | tr '\n' ' '`
	
    if [ -n "$errmsg" ]; then
        err "$errmsg"
    fi
	
    balance=`sed -n -e 's/<td style="padding: 0px;"><b>\(.*\)<\/b>/\1/p' $tmp_file | sed 's/,/\./p'`

	rm -f $tmp_cookie
    rm -f $tmp_file

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo kyivstar $1 $balance
	fi

}

function djuice {
    tmp_file=/tmp/djuice.response
    tmp_cookie=/tmp/djuice.cookies

    rv=0
    i=0
    page='https://my.djuice.ua/tbmb/login_djuice/show.do'
    while [ "$rv" != "200" ]; do
       curl -k -i -s -m $TIME_OUT $page > $tmp_file 

       rv=$(resp "$tmp_file")

       if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

    rv=0
    i=0
    page='https://my.djuice.ua'`grep "perform.do" $tmp_file | sed -e 's/.*<form.*action="\(.*\)" onsubmit.*/\1/p'`
    while [ "$rv" != "200" ]; do
       curl -k -i -s -m $TIME_OUT '$page' \
       --data-urlencode "user=$1" \
       -d "password=$2" > $tmp_file 

       rv=$(resp "$tmp_file")

       if [ "$rv" != "200" ]; then
			case "$rv" in
				"999")
					err999
					;;
				"404")
					err404 "$page"
					;;
				*)
					sleep $ATTEMPTS_TIME_OUT
					let i=i+1
					;;
			esac
		fi

		if [ $i -ge $ATTEMPTS ]; then
			errATT
		fi	
	done

    errmsg=`grep redError $tmp_file | grep '<td' | iconv -f cp1251 | sed -n -e 's/.*<td.*>\(.*\)<\/td>.*/\1/p' | tr '\n' ' '`
	if [ -n "$errmsg" ]; then
		err "$errmsg"
	fi
	
    balance=`cat $tmp_file | iconv -f cp1251 | tr '\n' ' ' | sed -n -e 's/.*<td.*><b>\(.*\)<\/b>.*<\/td>.*/\1/p'`

	rm -f $tmp_cookie
    rm -f $tmp_file

	if [ $VERBOSE -eq 0 ]; then
		echo $balance
	else
		echo djuice $1 $balance
	fi

}

function usage {
	echo "usage: $0 [-t{sec}] [-a{attempts}] [-T{sec_attempts}] [-s] [-v] [-h] {megafon|mts|beeline|mgts|onlime|qiwi|kyivstar|itc_ua} {login} [password]"
	echo "	-t Timeout for connections, default $TIME_OUT sec"
	echo "	-a Attempts of conections, default $ATTEMPTS"
	echo "	-T Sleep between attempts, default $ATTEMPTS_TIME_OUT"
	echo "	-s Silent, don't show any errors"
	echo "  -A Show account number (for itc_ua only)"
	echo "	-v Verbose, show operator name and login before balance"
	exit $1
}


while getopts "t:a:T:svh:A" optname; do
	case "$optname" in
		"t")
			if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
				usage 1
			else 
				TIME_OUT=$OPTARG
			fi
			;;
		"a")
			if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
				usage 1
			else
				ATTEMPTS=$OPTARG
			fi
			;;
		"T")
			if ! [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
				usage 1
			else
				ATTEMPTS_TIME_OUT=$OPTARG
			fi
			;;
		"A")
			SHOW_ACC=1
			;;
		"s")
			SILENT=1
			;;
		"v")
			VERBOSE=1
			;;
		"h")
			usage 0
			;;
		*)
			usage 1
			;;
	esac
done

p="${@:$OPTIND}"

voperator=`echo $p | cut -d' ' -f1`
vlogin=`echo $p | cut -d' ' -f2`
vpassword=`echo $p | cut -d' ' -f3`

if [ -z "$voperator" ] || [ -z "$vlogin" ] ; then
	usage 1
fi

if [ -z "$vpassword" ] ; then
    stty -echo
    read -p "Password: " vpassword; echo
    stty echo
fi

case "$voperator" in
	megafon)
		megafon $vlogin $vpassword
	;;
	corbina)
		corbina $vlogin $vpassword
	;;
	mts)
		mts $vlogin $vpassword
	;;
	mts_pda)
		mts_pda $vlogin $vpassword
	;;
	beeline)
		beeline $vlogin $vpassword
	;;
	mgts)
		mgts $vlogin $vpassword
	;;
	onlime)
		onlime $vlogin $vpassword
	;;
	qiwi)
		qiwi $vlogin $vpassword
	;;
	djuice)
		djuice $vlogin $vpassword
	;;
	kyivstar)
		kyivstar $vlogin $vpassword
	;;
	itc_ua_old)
		intertelecom_ua_old $vlogin $vpassword
	;;
	itc_ua)
		intertelecom_ua $vlogin $vpassword
	;;
	*)
		usage 1

esac

exit 0

