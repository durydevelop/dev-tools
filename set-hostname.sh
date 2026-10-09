#!/bin/bash

# ============================================================
# Raspberry Pi / Debian 13 Trixie
# Gestione hostname con NetworkManager
#
# Uso:
#   sudo ./set-hostname.sh nuovo-hostname
#   sudo ./set-hostname.sh -v
# ============================================================


# ------------------------------------------------------------
# Funzione di verifica
# ------------------------------------------------------------

check_hostname()
{
    local EXPECTED="$1"
    local ERRORS=0

    echo
    echo "----------------------------------------"
    echo "VERIFICA HOSTNAME"
    echo "----------------------------------------"


    # 1. Hostname kernel / attivo

    local CURRENT_HOSTNAME
    CURRENT_HOSTNAME=$(hostname)

    if [[ "$CURRENT_HOSTNAME" == "$EXPECTED" ]]; then
        echo "OK   hostname             : $CURRENT_HOSTNAME"
    else
        echo "ERR  hostname             : $CURRENT_HOSTNAME"
        echo "     atteso              : $EXPECTED"
        ERRORS=$((ERRORS + 1))
    fi


    # 2. hostnamectl --static

    local STATIC_HOSTNAME
    STATIC_HOSTNAME=$(hostnamectl --static 2>/dev/null)

    if [[ "$STATIC_HOSTNAME" == "$EXPECTED" ]]; then
        echo "OK   hostnamectl --static : $STATIC_HOSTNAME"
    else
        echo "ERR  hostnamectl --static : $STATIC_HOSTNAME"
        echo "     atteso              : $EXPECTED"
        ERRORS=$((ERRORS + 1))
    fi


    # 3. /etc/hostname

    if [[ -f /etc/hostname ]]; then

        local FILE_HOSTNAME
        FILE_HOSTNAME=$(tr -d '\r\n' < /etc/hostname)

        if [[ "$FILE_HOSTNAME" == "$EXPECTED" ]]; then
            echo "OK   /etc/hostname        : $FILE_HOSTNAME"
        else
            echo "ERR  /etc/hostname        : $FILE_HOSTNAME"
            echo "     atteso              : $EXPECTED"
            ERRORS=$((ERRORS + 1))
        fi

    else

        echo "ERR  /etc/hostname        : file inesistente"
        ERRORS=$((ERRORS + 1))

    fi


    # 4. NetworkManager

    if command -v nmcli >/dev/null 2>&1; then

        local NM_HOSTNAME
        NM_HOSTNAME=$(nmcli -g HOSTNAME general 2>/dev/null)

        if [[ -z "$NM_HOSTNAME" ]]; then
            NM_HOSTNAME=$(nmcli general hostname 2>/dev/null)
        fi

        if [[ "$NM_HOSTNAME" == "$EXPECTED" ]]; then
            echo "OK   NetworkManager       : $NM_HOSTNAME"
        else
            echo "ERR  NetworkManager       : $NM_HOSTNAME"
            echo "     atteso              : $EXPECTED"
            ERRORS=$((ERRORS + 1))
        fi

    else

        echo "ERR  NetworkManager       : nmcli non disponibile"
        ERRORS=$((ERRORS + 1))

    fi


    # 5. /etc/hosts

    if [[ -f /etc/hosts ]]; then

        local HOSTS_ENTRY
        HOSTS_ENTRY=$(awk '$1 == "127.0.1.1" {print $2; exit}' /etc/hosts)

        if [[ "$HOSTS_ENTRY" == "$EXPECTED" ]]; then
            echo "OK   /etc/hosts           : $HOSTS_ENTRY"
        else
            echo "ERR  /etc/hosts           : ${HOSTS_ENTRY:-non trovato}"
            echo "     atteso              : $EXPECTED"
            ERRORS=$((ERRORS + 1))
        fi

    else

        echo "ERR  /etc/hosts           : file inesistente"
        ERRORS=$((ERRORS + 1))

    fi


    # --------------------------------------------------------
    # Risultato
    # --------------------------------------------------------

    echo "----------------------------------------"

    if [[ $ERRORS -eq 0 ]]; then
        echo "OK: hostname verificato correttamente."
        echo "    $EXPECTED"
        return 0
    else
        echo "ERRORE: rilevati $ERRORS problemi."
        return 1
    fi
}


# ------------------------------------------------------------
# Controllo permessi
# ------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    echo "ERRORE: eseguire come root:"
    echo "  sudo $0 nuovo-hostname"
    echo "  sudo $0 -v"
    exit 1
fi


# ------------------------------------------------------------
# Modalità verifica
# ------------------------------------------------------------

if [[ "$1" == "-v" ]]; then

    # In modalità check l'hostname atteso è quello
    # attualmente configurato in /etc/hostname.

    if [[ ! -f /etc/hostname ]]; then
        echo "ERRORE: /etc/hostname non esiste."
        exit 1
    fi

    EXPECTED=$(tr -d '\r\n' < /etc/hostname)

    if [[ -z "$EXPECTED" ]]; then
        echo "ERRORE: /etc/hostname è vuoto."
        exit 1
    fi

    check_hostname "$EXPECTED"
    exit $?

fi


# ------------------------------------------------------------
# Controllo argomento hostname
# ------------------------------------------------------------

if [[ -z "$1" ]]; then

    echo "Uso:"
    echo "  sudo $0 nuovo-hostname"
    echo "  sudo $0 -v"
    exit 1

fi


NEW_HOSTNAME="$1"


# ------------------------------------------------------------
# Validazione hostname
# ------------------------------------------------------------

if [[ ! "$NEW_HOSTNAME" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
    echo "ERRORE: hostname non valido: $NEW_HOSTNAME"
    exit 1
fi

if (( ${#NEW_HOSTNAME} > 63 )); then
    echo "ERRORE: hostname troppo lungo (massimo 63 caratteri)."
    exit 1
fi


# ------------------------------------------------------------
# Mostra situazione attuale
# ------------------------------------------------------------

OLD_HOSTNAME=$(hostnamectl --static 2>/dev/null)

echo "Current ostname : $OLD_HOSTNAME"
echo "New hostname    : $NEW_HOSTNAME"
echo

echo -e -n "Are yo sure?"
read -p "(Y/n)" -n 1 -r
echo
if [[ $REPLY =~ ^[Nn]$ ]]; then
	exit 1
fi


# ------------------------------------------------------------
# Imposta hostname
# ------------------------------------------------------------

if ! hostnamectl set-hostname "$NEW_HOSTNAME"; then
    echo "ERRORE: hostnamectl set-hostname fallito."
    exit 1
fi


# ------------------------------------------------------------
# Aggiorna /etc/hosts
# ------------------------------------------------------------

if [[ ! -f /etc/hosts ]]; then
    echo "ERRORE: /etc/hosts non esiste."
    exit 1
fi


if grep -qE '^[[:space:]]*127\.0\.1\.1[[:space:]]' /etc/hosts; then

    sed -i \
        -E "s|^[[:space:]]*127\.0\.1\.1[[:space:]].*|127.0.1.1\t$NEW_HOSTNAME|" \
        /etc/hosts

else

    printf "127.0.1.1\t%s\n" "$NEW_HOSTNAME" >> /etc/hosts

fi


# ------------------------------------------------------------
# Verifica
# ------------------------------------------------------------

check_hostname "$NEW_HOSTNAME"
RESULT=$?


# ------------------------------------------------------------
# Risultato finale
# ------------------------------------------------------------

echo

if [[ $RESULT -eq 0 ]]; then
    echo "Hostname modificato correttamente."
else
    echo "ATTENZIONE: hostname modificato, ma la verifica ha"
    echo "rilevato delle incongruenze."
fi

exit $RESULT
