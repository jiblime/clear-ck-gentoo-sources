#!/bin/bash

if [[ -z "$(command -v equery)" ]] ; then
	echo -e "Missing app-portage/gentoolkit, exiting"
	return
fi

prep() {
        export $(grep CONFIG_MODULE_SIG_HASH /usr/src/linux/.config | tr -d '"')
        sig_hash="
                /usr/src/linux/scripts/sign-file \
                ${CONFIG_MODULE_SIG_HASH}"
        sig_kpem="
                /usr/src/linux/certs/signing_key.pem"
        sig_cert="
                /usr/src/linux/certs/signing_key.x509"

        sig_done="${sig_hash} ${sig_kpem} ${sig_cert}"
	sign
}

sign() {
	read -p "category/package name: " pkg

	for tosign in $(equery f ${pkg} | grep '\.ko' | tr '\n' '\ ') ; do
		${sig_done} ${tosign}
	done
}
prep
