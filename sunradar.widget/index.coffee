#
# ©2016 Lakiryt(らきりと)
# "Uebersicht Widget: Sun radar (multi-language)"
#
# Formulas/Formeln/計算式:
# http://www.pveducation.org/pvcdrom/properties-of-sunlight/suns-position & /elevation-angle
#

### The earth-sign (🌍) marks language-switches, for the case you want to translate user-visible parts to your language. ###

#⭐️ Language setting / Spracheinstellung / 言語設定
# "en" / "de" / "ja"
language: "en"

#⭐️ Set coordinates automatically / Koordinaten automatisch herausfinden / 緯度経度を自動検出
# "auto" / "manual"
findCoords: "auto"

#⭐️ Longitude (if set to manual) / Geographische Länge (falls auf manuell gestellt) / 経度（自動検出しない場合）
# negative at long. west / negativ bei westl. Länge / 西経は値が負になります
longitude: 40

#⭐️ Latitude (if set to manual) / Geographische Länge (falls auf manuell gestellt) / 経度（自動検出しない場合）
# negative at lat. south / negativ bei südl. Breite  / 南緯は値が腑になります
latitude: -80

#⭐️ Radius of the radar / Radius des Radars / レーダーの半径
radius_svg: 72

style: """
  //⭐️ margin top / Abstand nach oben / 上の余白
  top: 40%
  //⭐️ margin left / Abstand nach links / 左の余白
  left: 50px
  background: rgba(#fff, 0.6)
  color: rgba(#000, 0.8)
  font-family: "Helvetica-light"
  font-size: 12px
  padding: 10px 20px
  box-sizing: border-box
  -webkit-backdrop-filter: blur(20px)
  -webkit-font-smoothing: antialiased
  -webkit-border-radius: 5px
  image-rendering: crisp-edges

  h2
    padding: 0
    margin: 0
    font-size: 13px
    line-height: 1.3

  svg .ring, .axis
    stroke: #333
    stroke-width: 0.6px
    fill: none

  table
    line-height: 1.18

  .lang
    display: none
"""

######################################################################

command: """
  echo -n '{'

  # Difference to GMT in hours
  # Calculate in minutes to account for non-integer timezones:
  h0=$((`TZ=GMT date "+%H"` * 60 + `TZ=GMT date "+%M"`))
  h1=$((`date "+%H"` * 60 + `date "+%M"`))
  diff=`expr $h1 - $h0`
  if [ "${diff}" -lt "0" ]; then
    diff=`expr 1440 + ${diff}`
  fi
  # calculate fractional part by case-construct
  # (instead of doing it with e.g. float-operations)
  rem=$(( $diff % 60 ))
  case $rem in
    15)
        remInDecimal=".25"
        ;;
    30)
        remInDecimal=".5"
        ;;
    45)
        remInDecimal=".75"
        ;;
    *)
        remInDecimal=""
        ;;
  esac
  # Convert all variables back to hours
  diff=$(( $diff / 60 ))
  h1=$(( $h1 / 60 ))
  h0=$(( $h0 / 60 ))
  # Difference as decimal number
  echo -n '"deltaT":'${diff}${remInDecimal}','

  # Currennt hours, minutes, seconds
  echo -n '"h":"'${h1}'",'
  min=`date "+%M"`
  echo -n '"min":"'${min}'",'
  sec=`date "+%S"`
  echo -n '"sec":"'${sec}'",'

  # Days past since New Year
  d0=`date -j -f "%m %d" "01 01" "+%s"`
  tomorrow=`date -v+2d '+%m %d %Y'`
  d1=`date -j -f "%m %d %Y %T" "${tomorrow} 00:00:00" "+%s"`

  echo -n '"d":'$(( (d1 - d0) / 86400 ))

  echo -n '}'
"""



refreshFrequency: 1000

######################################################################

render: (output)->"""
<!--#{output}-->

<!--🌍-->
<h2 class="lang" id="en">Sun Radar</h2>
<h2 class="lang" id="de">Sonnenradar</h2>
<h2 class="lang" id="ja">太陽レーダー</h2>

<span id="jscontent"></span>

<svg version="1.1" xmlns="http://www.w3.org/2000/svg">

  <!--# Static objects #-->
  <!-- v: vertical; h: horizontal;
      r: tilted to right; l: tilted to left; -->

  <circle class="background" fill="rgba(0,0,0,0.1)" cx="50%" cy="50%" r="50%" />

  <line class="axis v" x1="50%" y1="0" x2="50%" y2="100%" />
  <line class="axis h" x1="0" y1="50%" x2="100%" y2="50%" />

  <line class="axis h r" x1="001" y1="25%" x2="002" y2="75%" />
  <line class="axis h l" x1="001" y1="75%" x2="002" y2="25%" />

  <line class="axis v r" x1="25%" y1="001" x2="75%" y2="002" />
  <line class="axis v l" x1="75%" y1="001" x2="25%" y2="002" />


  <circle class="ring" id="15" cx="50%" cy="50%" r="00" />
  <circle class="ring" id="30"  cx="50%" cy="50%" r="25%" />
  <circle class="ring" id="45" cx="50%" cy="50%" r="00" />
  <circle class="ring" id="60" cx="50%" cy="50%" r="00" />
  <circle class="ring" id="75" cx="50%" cy="50%" r="00" />
  <circle class="ring" id="90" cx="50%" cy="50%" r="00" />


  <!--# Moving objects #-->

  <line id="azimuth" x1="50%" y1="50%" x2="000" y2="000" stroke="#af5" />
  <circle id="sun" cx="000" cy="000" r="00" stroke="none" fill="#af5" />

</svg>
"""

######################################################################

afterRender: (domEl)->
  if @findCoords == "auto"
    geolocation.getCurrentPosition (e) =>
      coords     = e.position.coords
      [@latitude, @longitude] = [coords.latitude, coords.longitude]

  ### SVG plot (static) ###
  dom=$(domEl)
  r=@radius_svg

  to_deg = Math.PI/180
  sin = (rad) -> Math.sin(rad*to_deg)

  dom.find("svg")[0].setAttribute("width", 2*r)
  dom.find("svg")[0].setAttribute("height", 2*r)

  shortd=r*(1-sin(60))
  dom.find(".axis.h.r")[0].setAttribute("x1",shortd)
  dom.find(".axis.h.l")[0].setAttribute("x1",shortd)
  dom.find(".axis.v.r")[0].setAttribute("y1",shortd)
  dom.find(".axis.v.l")[0].setAttribute("y1",shortd)

  longd=r*(1+sin(60))
  dom.find(".axis.h.r")[0].setAttribute("x2",longd)
  dom.find(".axis.h.l")[0].setAttribute("x2",longd)
  dom.find(".axis.v.r")[0].setAttribute("y2",longd)
  dom.find(".axis.v.l")[0].setAttribute("y2",longd)


  dom.find(".ring#15")[0].setAttribute("r", r/6)
  dom.find(".ring#30")[0].setAttribute("r", 2*r/6)
  dom.find(".ring#45")[0].setAttribute("r", 3*r/6)
  dom.find(".ring#60")[0].setAttribute("r", 4*r/6)
  dom.find(".ring#75")[0].setAttribute("r", 5*r/6)
  dom.find(".ring#90")[0].setAttribute("r", r-1)

  dom.find("#sun")[0].setAttribute("r", r/24)

  switch @language #🌍
    when "de"
      dom.find(".lang#de")[0].style.display="inline"
    when "ja"
      dom.find(".lang#ja")[0].style.display="inline"
    else
      dom.find(".lang#en")[0].style.display="inline"

######################################################################

update: (output, domEl)->
  dom=$(domEl)

  obj=JSON.parse(output)
  jscontent="<table>"

  to_deg = Math.PI/180
  sin = (rad) -> Math.sin(rad*to_deg)
  cos = (rad) -> Math.cos(rad*to_deg)
  tan = (rad) -> Math.tan(rad*to_deg)
  asin = (rad) -> Math.asin(rad)*(1/to_deg)
  acos = (rad) -> Math.acos(rad)*(1/to_deg)


  ### Calculations ###
  ## Local Time ##
  # Current Time in hours.
  LocalTime = parseInt(obj.h) + parseInt(obj.min)/60 + parseInt(obj.sec)/3600

  # Variable for EoT and Declination. B=(360/365)*(d-81)
  B=(72/73)*(obj.d-81)

  ## Time Correction ##
  # 15*obj.deltaT : difference to GMT converted into degrees
  # The latter summand: the "Equation of Time"
  TC= 4*(@longitude- 15*obj.deltaT ) + (9.863*sin(2*B))-(7.53*cos(B))-(1.5*sin(B))

  ## Local Solar Time ##
  # Apply Time Correction to Local Time
  LST=LocalTime+(TC/60)
  LST-=24 if LST>24
  LST+=24 if LST<0

  ## Hour Angle ##
  # LST in degrees, where 0° is noon
  HRA=15*(LST-12)

  ## Declination ##
  Declination=23.45*sin(B)


  ### Formatting ###

  ## GMT diff ##
  if obj.deltaT>=12
    diffgmt="-"+(24-obj.deltaT)
  else
    diffgmt="+"+obj.deltaT

  ## Coordinates NSWE ##
  n__s= if @latitude<0 then "S," else "N,"
  e__w= if @longitude<0 then "W" else "E"


  ### Output ###
  switch @language #🌍
    when "de"
      jscontent+="<tr><td>Tage seit N.jahr:</td><td>"+(obj.d-1)+"</td></tr>"
      jscontent+="<tr><td>Zeitzone:</td><td>GMT"+diffgmt+"</td></tr>"
      jscontent+="<tr><td>Koordinaten:</td><td>"+Math.abs(Math.round(@latitude))+n__s+Math.abs(Math.round(@longitude))+e__w+"</td></tr>"
    when "ja"
      jscontent+="<tr><td>年始からの日数</td><td>"+(obj.d-1)+"</td></tr>"
      jscontent+="<tr><td>タイムゾーン</td><td>GMT"+diffgmt+"</td></tr>"
      jscontent+="<tr><td>緯度経度</td><td>"+Math.abs(Math.round(@latitude))+n__s+Math.abs(Math.round(@longitude))+e__w+"</td></tr>"
    else
      jscontent+="<tr><td>D since NYear:</td><td>"+obj.d+"</td></tr>"
      jscontent+="<tr><td>Timezone:</td><td>GMT"+diffgmt+"</td></tr>"
      jscontent+="<tr><td>Coordinates:</td><td>"+Math.abs(Math.round(@latitude))+n__s+Math.abs(Math.round(@longitude))+e__w+"</td></tr>"
  #jscontent+="<tr><td>B(Decl/EoT)</td><td>"+B.toFixed(14)+"</td></tr>"
  #jscontent+="<tr><td>TCorrFactor</td><td>"+TC.toFixed(12)+"</td></tr>"
  #jscontent+="<tr><td>LocalSolarT</td><td>"+LST.toFixed(13)+"</td></tr>"
  #jscontent+="<tr><td>HrAng (HRA)</td><td>"+HRA.toFixed(12)+"°</td></tr>"
  #jscontent+="<tr><td>Declination</td><td>"+Declination.toFixed(13)+"°</td></tr>"

  jscontent+='<tr><td colspan="2">&nbsp;</td></tr>'


  ### Elevation and Azimuth ###

  Elevation=asin(sin(Declination)*sin(@latitude)+cos(Declination)*cos(@latitude)*cos(HRA))

  jscontent+="<tr><td>"
  switch @language #🌍
    when "de"
      jscontent+="H&ouml;he:"
    when "ja"
      jscontent+="高度角"
    else
      jscontent+="Altitude:"
  jscontent+="</td><td>"+Math.round(Elevation*1000)/1000+"°</td></tr>"


  Azimuth = acos((sin(Declination)*cos(@latitude)-cos(Declination)*sin(@latitude)*cos(HRA))/cos(Elevation))
  if LST>12 or HRA>0
    Azimuth = 360-Azimuth

  jscontent+="<tr><td>"
  switch @language #🌍
    when "de"
      jscontent+="Azimut:"
    when "ja"
      jscontent+="方位角"
    else
      jscontent+="Azimuth:"
  jscontent+="</td><td>"+Math.round(Azimuth*1000)/1000+"°</td></tr>"


  ### Sunrise and Sunset ###
  Meridian=12-(TC/60)
  Deviation=acos(-tan(@latitude)*tan(Declination))/15

  if Deviation #i.e. if time of sunrise and sunset exist

    Time_Format = (hours, minutes, seconds) ->
      # Hours Formatting
      if hours<0
        hours="0"+(hours+24)
      if hours>23
        hours="0"+(hours-24)
      else
        hours="0"+hours

      hours=hours.toString().substr(hours.length-2)

      # Minutes Formatting
      minutes="0"+minutes
      minutes=minutes.substr(minutes.length-2)

      # Seconds Formatting and Final Output
      Return=hours+":"+minutes+":"
      Return+="0" if seconds.toFixed(2).toString().length==4
      Return+=seconds.toFixed(2)

      return Return


    ## Sunrise ##
    Sunrise_h=Math.floor(Meridian-Deviation)
    Sunrise_m=Math.floor(60*(Meridian-Deviation-Sunrise_h))
    Sunrise_s=3600*(Meridian-Deviation-Sunrise_h-Sunrise_m/60)

    Sunrise=Time_Format(Sunrise_h, Sunrise_m, Sunrise_s)

    jscontent+="<tr><td>"
    switch @language #🌍
      when "de"
        jscontent+="Aufgang:"
      when "ja"
        jscontent+="日の出"
      else
        jscontent+="Sunrise:"
    jscontent+="</td><td>"+Sunrise+"</td></tr>"


    ## Sunset ##
    Sunset_h=Math.floor(Meridian+Deviation)
    Sunset_m=Math.floor(60*(Meridian+Deviation-Sunset_h))
    Sunset_s=3600*(Meridian+Deviation-Sunset_h-Sunset_m/60)

    Sunset=Time_Format(Sunset_h,Sunset_m,Sunset_s)

    jscontent+="<tr><td>"
    switch @language #🌍
      when "de"
        jscontent+="Untergang:"
      when "ja"
        jscontent+="日の入"
      else
        jscontent+="Sunset:"
    jscontent+="</td><td>"+Sunset+"</td></tr>"

  else
    jscontent+='<tr><td colspan="2"><small>'
    switch @language #🌍
      when "de"
        pole = if @latitude<0 then "Antarktis" else "Arktis"
        jscontent+="Kein Sonnen Auf- oder Untergang.<br>("+pole+")"
      when "ja"
        pole = if @latitude<0 then "南" else "北"
        jscontent+="日の出・日の入はありません。<br>（"+pole+"極圏内のため）"
      else
        pole = if @latitude<0 then "Antarctic" else "Arctic"
        jscontent+="No sunrise or sunset.<br>("+pole+" region)"
    jscontent+="</small></td></tr>"


  jscontent+="</table>"

  dom.find("#jscontent").html(jscontent)


  ### SVG plot (moving) ###

  r=@radius_svg

  ## Azimuth line ##

  x2=r*(1+0.99*sin(Azimuth))
  y2=r*(1-0.99*cos(Azimuth))

  dom.find("#azimuth")[0].setAttribute("x2", x2)
  dom.find("#azimuth")[0].setAttribute("y2", y2)


  ## Azimuth point ##

  cx=r*(1+sin(Azimuth)*(90-Math.abs(Elevation))/90) #linear
  cy=r*(1-cos(Azimuth)*(90-Math.abs(Elevation))/90)

  dom.find("#sun")[0].setAttribute("cx", cx)
  dom.find("#sun")[0].setAttribute("cy", cy)


  ## Azimuth point color ##

  if Elevation<0
    dom.find("#sun")[0].setAttribute("fill", "#69a")
