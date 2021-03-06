if [ "$FREETZ_REMOVE_TR069" == "y" -o "$FREETZ_REMOVE_ASSISTANT" == "y" ]; then
	[ -e "${HTML_LANG_MOD_DIR}/html/logincheck.html" ] && modsed \
	  's/\(^var doTr069 = \).*/\1false;/g' \
	  "${HTML_LANG_MOD_DIR}/html/logincheck.html"
	modsed \
	  's!http.redirect("/tr69_autoconfig/.*!go_home()!g' \
	  "${LUA_MOD_DIR}/first.lua"

	modsed -r \
	  '/^[ \t]*box[.]get[.]wiztype[ \t]*=/ {
	    N
	    /\n[ \t]*return "tr069[^"]*"/ {
	        s,^([ \t]*)([^\n]*)\n([ \t]*)([^\n]*)$,\1--\2\n\3--\4\n\3return first.go_home(),
	    }
	  }' \
	  "${LUA_MOD_DIR}/first.lua"
fi

[ "$FREETZ_REMOVE_TR069" == "y" ] || return 0

echo1 "removing tr069 stuff"
rm_files \
  "${FILESYSTEM_MOD_DIR}/sbin/tr069discover" \
  "${HTML_LANG_MOD_DIR}/tr69_autoconfig/"

if [ "$FREETZ_REMOVE_TR064" == "y" ]; then
	echo1 "removing tr064 stuff"
	rm_files \
	  "${FILESYSTEM_MOD_DIR}/usr/share/ctlmgr/libtr064.so" \
	  "${FILESYSTEM_MOD_DIR}/usr/share/ctlmgr/libtr069.so" \
	  "${FILESYSTEM_MOD_DIR}/etc/websrv_tr064_ssl_key.pem"
fi

[ "$FREETZ_REMOVE_TR069_FWUPDATE" == "y" ] && rm_files "${FILESYSTEM_MOD_DIR}/usr/bin/tr069fwupdate"
[ "$FREETZ_REMOVE_TR069_HTTPSDL" == "y" ] && rm_files "${FILESYSTEM_MOD_DIR}/usr/bin/httpsdl"
if [ "$FREETZ_REMOVE_TR069_PROVIDERS" == "y" ]; then
	rm_files "${FILESYSTEM_MOD_DIR}/etc/default.Fritz_Box_*/*/providers-*.tar"
	[ -e "${HTML_LANG_MOD_DIR}/lua/isp.lua" ] && sedfile="${HTML_LANG_MOD_DIR}/lua/isp.lua" || sedfile="${FILESYSTEM_MOD_DIR}/usr/lua/isp.lua"
	modsed \
	  's!\(list\[other.id\].providername=other.name\)!if other.id~=nil then\n\1\nend!' \
	  "$sedfile"
fi
[ "$FREETZ_REMOVE_TR069_VOIPPROVIDERS" == "y" ] && rm_files "${FILESYSTEM_MOD_DIR}/etc/default.Fritz_Box_*/*/voip_providers-*.tar"

# verhindert Nagscreen nach dem ersten Login mit Erlaubnis fuer Diagnosedaten und Portforward
modsed \
  's!.*local diagInconsistent *=!&false --OLD VALUE: !' \
  "${LUA_MOD_DIR}/first.lua"

# patcht Heimnetz > Netzwerk > Netzwerkeinstellungen > Heimnetzfreigaben > Zugriff für Anwendungen zulassen
sedfile="${HTML_LANG_MOD_DIR}/net/network_settings.lua"
if [ "$FREETZ_REMOVE_TR064" == "y" -a -e $sedfile ]; then
	echo1 "patching ${sedfile##*/}"
	#<input type="checkbox" id="uiViewSetTr064" name="set_tr_064" <?lua if g_var.tr064_enabled then box.out('checked') end ?>>
	#<label for="uiViewSetTr064">{?859:511?}</label>
	#<p class="form_checkbox_explain">
	#{?859:2438?}
	#</p>
	#<p class="form_checkbox_explain">
	#{?859:144?}
	#</p>
	mod_del_area \
	  'id="uiViewSetTr064"' \
	  0 \
	  '{?859:144?}' \
	  1 \
	  $sedfile
	# remove sub header if also upnp is removed
	if [ "$FREETZ_REMOVE_UPNP" == "y" ]; then
		#<h4>
		#{?859:570?}
		#</h4>
		mod_del_area \
		  '{?859:570?}' \
		  -1 \
		  +1 \
		  $sedfile
		#if (general.is_expert()) then box.out([[<hr>]]) end
		modsed '/general.is_expert.*then.box.out.*hr.*end/d' $sedfile
	fi
fi

echo1 "patching default tr069.cfg"
find ${FILESYSTEM_MOD_DIR}/etc -name tr069.cfg -exec $SED -e 's/enabled = yes/enabled = no/' -i '{}' \;

if [ -e "${FILESYSTEM_MOD_DIR}/etc/init.d/rc.init" ]; then
	echo1 "patching /etc/init.d/rc.init"
	modsed "s/TR069=y/TR069=n/g" "${FILESYSTEM_MOD_DIR}/etc/init.d/rc.init" "TR069=n$"
else
	echo1 "patching /etc/init.d/rc.conf"
	modsed "s/CONFIG_TR069=.*$/CONFIG_TR069=\"n\"/g" "${FILESYSTEM_MOD_DIR}/etc/init.d/rc.conf" "CONFIG_TR069=\"n\"$"
	[ "$FREETZ_REMOVE_TR064" == "y" ] && \
	modsed "s/CONFIG_TR064=.*$/CONFIG_TR064=\"n\"/g" "${FILESYSTEM_MOD_DIR}/etc/init.d/rc.conf" "CONFIG_TR064=\"n\"$"
fi

# delete tr069 config
echo "echo -n > /var/flash/tr069.cfg" > "${FILESYSTEM_MOD_DIR}/bin/tr069starter"

