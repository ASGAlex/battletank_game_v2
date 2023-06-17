<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.1" name="ground" tilewidth="8" tileheight="8" tilecount="6" columns="3">
 <image source="../images/ground_tiles.png" width="24" height="16"/>
 <tile id="0" type="grass">
  <animation>
   <frame tileid="3" duration="700"/>
   <frame tileid="4" duration="700"/>
   <frame tileid="5" duration="700"/>
  </animation>
 </tile>
 <tile id="1" type="sand"/>
 <tile id="2" type="ash"/>
 <tile id="3" type="sand_slow">
  <animation>
   <frame tileid="3" duration="700"/>
   <frame tileid="4" duration="700"/>
   <frame tileid="3" duration="700"/>
   <frame tileid="4" duration="700"/>
   <frame tileid="5" duration="700"/>
   <frame tileid="3" duration="700"/>
   <frame tileid="4" duration="700"/>
   <frame tileid="5" duration="700"/>
  </animation>
 </tile>
 <wangsets>
  <wangset name="Безымянный набор" type="edge" tile="-1"/>
 </wangsets>
</tileset>
