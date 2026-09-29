#!/usr/bin/env bash
# user-info.sh - Riepilogo leggibile di un account utente Linux
# Uso: ./user-info.sh [nome_utente]      (default: robolab)
#
# Esegue: getent passwd, id, getent group, sudo passwd -S
# e ne mostra l'output in forma comprensibile.

set -u

USERNAME="${1:-robolab}"

# Colori solo se l'output è un terminale
if [[ -t 1 ]]; then
  B=$'\e[1m'; R=$'\e[31m'; G=$'\e[32m'; Y=$'\e[33m'; C=$'\e[36m'; N=$'\e[0m'
else
  B=''; R=''; G=''; Y=''; C=''; N=''
fi

title() { printf '\n%s== %s ==%s\n' "$B$C" "$1" "$N"; }
row()   { printf '  %s%-24s%s %s\n' "$B" "$1" "$N" "$2"; }
ok()    { printf '  %s✔%s %s\n' "$G" "$N" "$1"; }
warn()  { printf '  %s⚠%s %s\n' "$Y" "$N" "$1"; }
bad()   { printf '  %s✘%s %s\n' "$R" "$N" "$1"; }

# ---------------------------------------------------------------
# 1) getent passwd
# ---------------------------------------------------------------
title "Account (getent passwd $USERNAME)"
if ! entry=$(getent passwd "$USERNAME"); then
  bad "L'utente '$USERNAME' non esiste"
  exit 1
fi

IFS=: read -r name _ uid gid gecos home shell <<< "$entry"
home_note=""
[[ -d $home ]] || home_note=" (la directory non esiste)"

row "Nome utente"        "$name"
row "UID"                "$uid"
row "GID primario"       "$gid"
row "Descrizione (GECOS)" "${gecos:-—}"
row "Home directory"     "$home$home_note"
row "Shell di login"     "$shell"

case "$shell" in
  */nologin|*/false) warn "Login interattivo disabilitato" ;;
  *)                 ok   "Login interattivo consentito" ;;
esac

if   (( uid == 0 ));   then warn "UID 0: account con privilegi di root"
elif (( uid < 1000 )); then warn "UID < 1000: probabile account di sistema"
else                        ok   "Account utente normale"
fi

# ---------------------------------------------------------------
# 2) id
# ---------------------------------------------------------------
title "Identità e gruppi (id $USERNAME)"
primary_group=$(id -gn "$USERNAME")
all_groups=$(id -Gn "$USERNAME")
supp=$(tr ' ' '\n' <<< "$all_groups" | grep -vx "$primary_group" | paste -sd, - | sed 's/,/, /g')

row "Gruppo primario"      "$primary_group (GID $(id -g "$USERNAME"))"
row "Gruppi supplementari" "${supp:-nessuno}"

groups_padded=" $all_groups "
if [[ $groups_padded == *" sudo "* || $groups_padded == *" wheel "* || $groups_padded == *" admin "* ]]; then
  warn "Può ottenere privilegi di amministratore (sudo/wheel/admin)"
fi
if [[ $groups_padded == *" docker "* ]]; then
  warn "Gruppo 'docker': di fatto equivale ad avere accesso root"
fi

# ---------------------------------------------------------------
# 3) getent group
# ---------------------------------------------------------------
title "Gruppo (getent group $USERNAME)"
if gentry=$(getent group "$USERNAME"); then
  IFS=: read -r gname _ ggid members <<< "$gentry"
  row "Nome gruppo" "$gname"
  row "GID"         "$ggid"
  if [[ -n $members ]]; then
    row "Membri supplementari" "${members//,/, }"
  else
    row "Membri supplementari" "nessuno (normale se è solo il gruppo primario)"
  fi
else
  warn "Non esiste un gruppo chiamato '$USERNAME'"
fi

# ---------------------------------------------------------------
# 4) passwd -S (richiede root)
# ---------------------------------------------------------------
title "Stato password (passwd -S $USERNAME)"
if (( EUID == 0 )); then
  status=$(passwd -S "$USERNAME" 2>&1); rc=$?
elif command -v sudo >/dev/null 2>&1; then
  status=$(sudo passwd -S "$USERNAME" 2>&1); rc=$?
else
  status="sudo non disponibile"; rc=1
fi

if (( rc != 0 )); then
  bad "Impossibile leggere lo stato della password: $status"
else
  read -r _ st last min max warn_days inactive _ <<< "$status"

  case "$st" in
    P)      ok  "Password impostata e utilizzabile" ;;
    L|LK)   bad "Account bloccato" ;;
    NP)     warn "Nessuna password impostata" ;;
    *)      warn "Stato sconosciuto: $st" ;;
  esac

  row "Ultimo cambio password" "$last"
  row "Minimo tra due cambi"   "$min giorni"
  if [[ $max == 99999 ]]; then
    row "Validità massima"     "nessuna scadenza"
  else
    row "Validità massima"     "$max giorni"
  fi
  row "Preavviso scadenza"     "$warn_days giorni"
  if [[ $inactive == -1 ]]; then
    row "Blocco per inattività" "disabilitato"
  else
    row "Blocco per inattività" "dopo $inactive giorni dalla scadenza"
  fi
fi

echo
