#!/usr/bin/env bash
if [ -z "$BASH" ] ; then
   bash  $0
   exit
fi



my_name=$0


function setup_environment {
  bf=""
  n=""
  ORGANISATION="UFRGS - Universidade Federal do Rio Grande do Sul"
  URL="http://www.ufrgs.br/cpd"
  SUPPORT="suporteti@ufrgs.br"
if [ ! -z "$DISPLAY" ] ; then
  if which zenity 1>/dev/null 2>&1 ; then
    ZENITY=`which zenity`
  elif which kdialog 1>/dev/null 2>&1 ; then
    KDIALOG=`which kdialog`
  else
    if tty > /dev/null 2>&1 ; then
      if  echo $TERM | grep -E -q "xterm|gnome-terminal|lxterminal"  ; then
        bf="[1m";
        n="[0m";
      fi
    else
      find_xterm
      if [ -n "$XT" ] ; then
        $XT -e $my_name
      fi
    fi
  fi
fi
}

function split_line {
echo $1 | awk  -F '\\\\n' 'END {  for(i=1; i <= NF; i++) print $i }'
}

function find_xterm {
terms="xterm aterm wterm lxterminal rxvt gnome-terminal konsole"
for t in $terms
do
  if which $t > /dev/null 2>&1 ; then
  XT=$t
  break
  fi
done
}


function ask {
     T="eduroam CAT"
#  if ! [ -z "$3" ] ; then
#     T="$T: $3"
#  fi
  if [ ! -z $KDIALOG ] ; then
     if $KDIALOG --yesno "${1}\n${2}?" --title "$T" ; then
       return 0
     else
       return 1
     fi
  fi
  if [ ! -z $ZENITY ] ; then
     text=`echo "${1}" | fmt -w60`
     if $ZENITY --no-wrap --question --text="${text}\n${2}?" --title="$T" 2>/dev/null ; then
       return 0
     else
       return 1
     fi
  fi

  yes=S
  no=N
  yes1=`echo $yes | awk '{ print toupper($0) }'`
  no1=`echo $no | awk '{ print toupper($0) }'`

  if [ $3 == "0" ]; then
    def=$yes
  else
    def=$no
  fi

  echo "";
  while true
  do
  split_line "$1"
  read -p "${bf}$2 ${yes}/${no}? [${def}]:$n " answer
  if [ -z "$answer" ] ; then
    answer=${def}
  fi
  answer=`echo $answer | awk '{ print toupper($0) }'`
  case "$answer" in
    ${yes1})
       return 0
       ;;
    ${no1})
       return 1
       ;;
  esac
  done
}

function alert {
  if [ ! -z $KDIALOG ] ; then
     $KDIALOG --sorry "${1}"
     return
  fi
  if [ ! -z $ZENITY ] ; then
     $ZENITY --warning --text="$1" 2>/dev/null
     return
  fi
  echo "$1"

}

function show_info {
  if [ ! -z $KDIALOG ] ; then
     $KDIALOG --msgbox "${1}"
     return
  fi
  if [ ! -z $ZENITY ] ; then
     $ZENITY --info --width=500 --text="$1" 2>/dev/null
     return
  fi
  split_line "$1"
}

function confirm_exit {
  if [ ! -z $KDIALOG ] ; then
     if $KDIALOG --yesno "Tem a certeza que pretende desistir?"  ; then
     exit 1
     fi
  fi
  if [ ! -z $ZENITY ] ; then
     if $ZENITY --question --text="Tem a certeza que pretende desistir?" 2>/dev/null ; then
        exit 1
     fi
  fi
}



function prompt_nonempty_string {
  prompt=$2
  if [ ! -z $ZENITY ] ; then
    if [ $1 -eq 0 ] ; then
     H="--hide-text "
    fi
    if ! [ -z "$3" ] ; then
     D="--entry-text=$3"
    fi
  elif [ ! -z $KDIALOG ] ; then
    if [ $1 -eq 0 ] ; then
     H="--password"
    else
     H="--inputbox"
    fi
  fi


  out_s="";
  if [ ! -z $ZENITY ] ; then
    while [ ! "$out_s" ] ; do
      out_s=`$ZENITY --entry --width=300 $H $D --text "$prompt" 2>/dev/null`
      if [ $? -ne 0 ] ; then
        confirm_exit
      fi
    done
  elif [ ! -z $KDIALOG ] ; then
    while [ ! "$out_s" ] ; do
      out_s=`$KDIALOG $H "$prompt" "$3"`
      if [ $? -ne 0 ] ; then
        confirm_exit
      fi
    done  
  else
    while [ ! "$out_s" ] ; do
      read -p "${prompt}: " out_s
    done
  fi
  echo "$out_s";
}

function user_cred {
  PASSWORD="a"
  PASSWORD1="b"

  if ! USER_NAME=`prompt_nonempty_string 1 "introduza o seu userid"` ; then
    exit 1
  fi

  while [ "$PASSWORD" != "$PASSWORD1" ]
  do
    if ! PASSWORD=`prompt_nonempty_string 0 "introduza a sua password"` ; then
      exit 1
    fi
    if ! PASSWORD1=`prompt_nonempty_string 0 "repita a sua password"` ; then
      exit 1
    fi
    if [ "$PASSWORD" != "$PASSWORD1" ] ; then
      alert "as passwords não coincidem"
    fi
  done
}
setup_environment
show_info "Este instalador foi criado para a/o ${ORGANISATION}\n\nMais informações e comentários:\n\nEMAIL: ${SUPPORT}\nWWW: ${URL}\n\nInstalador criado com software do projecto GEANT."
if ! ask "Este instalador só funcionará correctamente se for membro de ${bf}UFRGS - Universidade Federal do Rio Grande do Sul.${n}" "Continue" 1 ; then exit; fi
if [ -d $HOME/.cat_installer ] ; then
   if ! ask "A diretoria $HOME/.cat_installer já existe; alguns dos ficheiros podem ser sobrepostos. " "Continue" 1 ; then exit; fi
else
  mkdir $HOME/.cat_installer
fi
# save certificates
echo "-----BEGIN CERTIFICATE-----
MIIFCTCCA/GgAwIBAgIQV0cXGWPWQYpD97TkhRl8LzANBgkqhkiG9w0BAQsFADCB
0DELMAkGA1UEBhMCQlIxHzAdBgNVBAgTFlJpbyBHcmFuZGUgZG8gU3VsIC0gUlMx
FTATBgNVBAcTDFBvcnRvIEFsZWdyZTE6MDgGA1UEChMxVW5pdmVyc2lkYWRlIEZl
ZGVyYWwgZG8gUmlvIEdyYW5kZSBkbyBTdWwgLSBVRlJHUzEvMC0GA1UECxMmQ2Vu
dHJvIGRlIFByb2Nlc3NhbWVudG8gZGUgRGFkb3MgLSBDUEQxHDAaBgNVBAMTE0FD
IFJhaXogZGEgVUZSR1MgdjIwHhcNMTIwNDA5MTQyNTQ2WhcNMzIwNDA5MTQzNTQ1
WjCB0DELMAkGA1UEBhMCQlIxHzAdBgNVBAgTFlJpbyBHcmFuZGUgZG8gU3VsIC0g
UlMxFTATBgNVBAcTDFBvcnRvIEFsZWdyZTE6MDgGA1UEChMxVW5pdmVyc2lkYWRl
IEZlZGVyYWwgZG8gUmlvIEdyYW5kZSBkbyBTdWwgLSBVRlJHUzEvMC0GA1UECxMm
Q2VudHJvIGRlIFByb2Nlc3NhbWVudG8gZGUgRGFkb3MgLSBDUEQxHDAaBgNVBAMT
E0FDIFJhaXogZGEgVUZSR1MgdjIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
AoIBAQDvCmjv3cCM0wZHaF7fHlFIQwbFimXNGQxMAajDaDC6QAubbRVYGuIqscoY
8IlBgXXrFlrZVj377S9Ve5PncEh3bJeJuvIhgo2Vt6QGBiquiMqciWFtgXIFIqjn
rZnGa3UumxMgY+jWsfM29Lk69pARdW31XyPbiVwOKZcZ/RyB01RRS2NLOvssvKaS
XB6vXi4MJ42EoXtLV8tEFh1+ut7RzwzzsvN6rCWLE3I2cXlPBHOHdVECWgricxZA
4Q6m9GZF3Rx0MY5Lrx8B9cCDbHRfxMVS4vzEviMrBid+S8pvd8GwliH6AXEEJZeW
AJG1sRVCT1wTlUs21asYXJ17t1D9AgMBAAGjgdwwgdkwCwYDVR0PBAQDAgGGMA8G
A1UdEwEB/wQFMAMBAf8wHQYDVR0OBBYEFPC2+TnNd301pBWHLhXqXNNStGz8MD0G
A1UdHwQ2MDQwMqAwoC6GLGh0dHA6Ly93d3cudWZyZ3MuYnIvcGtpL0xDUkFDUmFp
elVGUkdTdjIuY3JsMBAGCSsGAQQBgjcVAQQDAgEAMEkGCCsGAQUFBwEBBD0wOzA5
BggrBgEFBQcwAoYtaHR0cDovL3d3dy51ZnJncy5ici9wa2kvY2VydEFDUmFpelVG
UkdTdjIuY3J0MA0GCSqGSIb3DQEBCwUAA4IBAQBkaJBm2uNtKx9OEdUuvhT3hGLt
lScQJfC29Vgsk7zDGEvN2xKDH8JDGsox8G9ZYsPkyNOT5TfAc334YxALq4LWZSuY
l0xsuv4th+8qGIfZjjO1ye0/Z8paLcRLsEC+OR7S+kozsDjibLjSsWqYG04d7jvG
W8Vhr+0yJqyGN9NiCPpRRTzvpbVpVN0scOhZpZ9vZSfbYnm04ueOEWBgybPXBZPD
gurFALXB+uONxuNfR33T15PYLeVaaaDlXQ1krupKj9SbiKtBXghTau7ob8pCSBX4
960mgdCu70CgA6lIFhhW3uaYifAS/h7hdOON3++dFj4FH8My1AUzwnvUtxs0
-----END CERTIFICATE-----

" > $HOME/.cat_installer/ca.pem
function run_python_script {
PASSWORD=$( echo "$PASSWORD" | sed "s/'/\\\'/g" )
if python << EEE1 > /dev/null 2>&1
import dbus
EEE1
then
    PYTHON=python
elif python3 << EEE2 > /dev/null 2>&1
import dbus
EEE2
then
    PYTHON=python3
else
    PYTHON=none
    return 1
fi

$PYTHON << EOF > /dev/null 2>&1
#-*- coding: utf-8 -*-
import dbus
import re
import sys
import uuid
import os

class EduroamNMConfigTool:

    def connect_to_NM(self):
        #connect to DBus
        try:
            self.bus = dbus.SystemBus()
        except dbus.exceptions.DBusException:
            print("Can't connect to DBus")
            sys.exit(2)
        #main service name
        self.system_service_name = "org.freedesktop.NetworkManager"
        #check NM version
        self.check_nm_version()
        if self.nm_version == "0.9" or self.nm_version == "1.0":
            self.settings_service_name = self.system_service_name
            self.connection_interface_name = "org.freedesktop.NetworkManager.Settings.Connection"
            #settings proxy
            sysproxy = self.bus.get_object(self.settings_service_name, "/org/freedesktop/NetworkManager/Settings")
            #settings intrface
            self.settings = dbus.Interface(sysproxy, "org.freedesktop.NetworkManager.Settings")
        elif self.nm_version == "0.8":
            #self.settings_service_name = "org.freedesktop.NetworkManagerUserSettings"
            self.settings_service_name = "org.freedesktop.NetworkManager"
            self.connection_interface_name = "org.freedesktop.NetworkManagerSettings.Connection"
            #settings proxy
            sysproxy = self.bus.get_object(self.settings_service_name, "/org/freedesktop/NetworkManagerSettings")
            #settings intrface
            self.settings = dbus.Interface(sysproxy, "org.freedesktop.NetworkManagerSettings")
        else:
            print("This Network Manager version is not supported")
            sys.exit(2)

    def check_opts(self):
        self.cacert_file = '${HOME}/.cat_installer/ca.pem'
        self.pfx_file = '${HOME}/.cat_installer/user.p12'
        if not os.path.isfile(self.cacert_file):
            print("Certificate file not found, looks like a CAT error")
            sys.exit(2)

    def check_nm_version(self):
        try:
            proxy = self.bus.get_object(self.system_service_name, "/org/freedesktop/NetworkManager")
            props = dbus.Interface(proxy, "org.freedesktop.DBus.Properties")
            version = props.Get("org.freedesktop.NetworkManager", "Version")
        except dbus.exceptions.DBusException:
            version = "0.8"
        if re.match(r'^1\.', version):
            self.nm_version = "1.0"
            return
        if re.match(r'^0\.9', version):
            self.nm_version = "0.9"
            return
        if re.match(r'^0\.8', version):
            self.nm_version = "0.8"
            return
        else:
            self.nm_version = "Unknown version"
            return

    def byte_to_string(self, barray):
        return "".join([chr(x) for x in barray])


    def delete_existing_connections(self, ssid):
        "checks and deletes earlier connections"
        try:
            conns = self.settings.ListConnections()
        except dbus.exceptions.DBusException:
            print("DBus connection problem, a sudo might help")
            exit(3)
        for each in conns:
            con_proxy = self.bus.get_object(self.system_service_name, each)
            connection = dbus.Interface(con_proxy, "org.freedesktop.NetworkManager.Settings.Connection")
            try:
               connection_settings = connection.GetSettings()
               if connection_settings['connection']['type'] == '802-11-wireless':
                   conn_ssid = self.byte_to_string(connection_settings['802-11-wireless']['ssid'])
                   if conn_ssid == ssid:
                       connection.Delete()
            except dbus.exceptions.DBusException:
               pass

    def add_connection(self,ssid):
        server_alt_subject_name_list = dbus.Array({'DNS:radius3.ufrgs.br'})
        server_name = 'radius3.ufrgs.br'
        if self.nm_version == "0.9" or self.nm_version == "1.0":
             match_key = 'altsubject-matches'
             match_value = server_alt_subject_name_list
        else:
             match_key = 'subject-match'
             match_value = server_name
            
        s_con = dbus.Dictionary({
            'type': '802-11-wireless',
            'uuid': str(uuid.uuid4()),
            'permissions': ['user:$USER'],
            'id': ssid 
        })
        s_wifi = dbus.Dictionary({
            'ssid': dbus.ByteArray(ssid.encode('utf8')),
            'security': '802-11-wireless-security'
        })
        s_wsec = dbus.Dictionary({
            'key-mgmt': 'wpa-eap',
            'proto': ['rsn',],
            'pairwise': ['ccmp',],
            'group': ['ccmp', 'tkip']
        })
        s_8021x = dbus.Dictionary({
            'eap': ['peap'],
            'identity': '$USER_NAME',
            'ca-cert': dbus.ByteArray("file://{0}\0".format(self.cacert_file).encode('utf8')),
             match_key: match_value,
            'password': '$PASSWORD',
            'phase2-auth': 'mschapv2',
        })
        s_ip4 = dbus.Dictionary({'method': 'auto'})
        s_ip6 = dbus.Dictionary({'method': 'auto'})
        con = dbus.Dictionary({
            'connection': s_con,
            '802-11-wireless': s_wifi,
            '802-11-wireless-security': s_wsec,
            '802-1x': s_8021x,
            'ipv4': s_ip4,
            'ipv6': s_ip6
        })
        self.settings.AddConnection(con)

    def main(self):
        self.check_opts()
        ver = self.connect_to_NM()
        self.delete_existing_connections('eduroam')
        self.add_connection('eduroam')

if __name__ == "__main__":
    ENMCT = EduroamNMConfigTool()
    ENMCT.main()
EOF
}
function create_wpa_conf {
cat << EOFW >> $HOME/.cat_installer/cat_installer.conf

network={
  ssid="eduroam"
  key_mgmt=WPA-EAP
  pairwise=CCMP
  group=CCMP TKIP
  eap=PEAP
  ca_cert="${HOME}/.cat_installer/ca.pem"
  identity="${USER_NAME}"
  domain_suffix_match="radius3.ufrgs.br"
  phase2="auth=MSCHAPV2"
  password="${PASSWORD}"
}
EOFW
chmod 600 $HOME/.cat_installer/cat_installer.conf
}
#prompt user for credentials
  user_cred
  if run_python_script ; then
   show_info "Instalação realizada com sucesso"
else
   show_info "Configuração através do Network Manager falhou, a gerar o ficheiro de configuração wpa_supplicant.conf"
   if ! ask "Network Manager configuration failed, but we may generate a wpa_supplicant configuration file if you wish. Be warned that your connection password will be saved in this file as clear text." "Escreva o ficheiro" 1 ; then exit ; fi

if [ -f $HOME/.cat_installer/cat_installer.conf ] ; then
  if ! ask "O ficheiro $HOME/.cat_installer/cat_installer.conf já existe; será sobreposto. " "Continue" 1 ; then confirm_exit; fi
  rm $HOME/.cat_installer/cat_installer.conf
  fi
   create_wpa_conf
   show_info "Resultado armazenado em $HOME/.cat_installer/cat_installer.conf"
fi
