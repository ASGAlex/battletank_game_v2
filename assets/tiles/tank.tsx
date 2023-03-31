<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.9" tiledversion="1.9.2" name="tank" tilewidth="14" tileheight="16" tilecount="18" columns="3">
 <image source="../images/spritesheets/tank_basic2.png" width="42" height="96"/>
 <tile id="0" class="simple">
  <properties>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="1500"/>
   <property name="health" type="float" value="1"/>
   <property name="speed" type="int" value="55"/>
  </properties>
  <animation>
   <frame tileid="0" duration="200"/>
   <frame tileid="1" duration="200"/>
  </animation>
 </tile>
 <tile id="1" class="simple_idle"/>
 <tile id="2" class="simple_wreck"/>
 <tile id="3" class="middle">
  <properties>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="1250"/>
   <property name="health" type="float" value="2"/>
   <property name="speed" type="int" value="50"/>
  </properties>
  <animation>
   <frame tileid="3" duration="200"/>
   <frame tileid="4" duration="200"/>
  </animation>
 </tile>
 <tile id="4" class="middle_idle"/>
 <tile id="5" class="middle_wreck"/>
 <tile id="6" class="advanced">
  <properties>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="850"/>
   <property name="health" type="float" value="2"/>
   <property name="speed" type="int" value="45"/>
  </properties>
  <animation>
   <frame tileid="6" duration="200"/>
   <frame tileid="7" duration="200"/>
  </animation>
 </tile>
 <tile id="7" class="advanced_idle"/>
 <tile id="8" class="advanced_wreck"/>
 <tile id="9" class="heavy">
  <properties>
   <property name="damage" type="float" value="2"/>
   <property name="fireDelay" type="int" value="1000"/>
   <property name="health" type="float" value="3"/>
   <property name="speed" type="int" value="35"/>
  </properties>
  <animation>
   <frame tileid="9" duration="200"/>
   <frame tileid="10" duration="200"/>
  </animation>
 </tile>
 <tile id="10" class="heavy_idle"/>
 <tile id="11" class="heavy_wreck"/>
 <tile id="12" class="fast">
  <properties>
   <property name="damage" type="float" value="0.25"/>
   <property name="fireDelay" type="int" value="500"/>
   <property name="health" type="float" value="1"/>
   <property name="speed" type="int" value="70"/>
  </properties>
  <animation>
   <frame tileid="12" duration="200"/>
   <frame tileid="13" duration="200"/>
  </animation>
 </tile>
 <tile id="13" class="fast_idle"/>
 <tile id="14" class="fast_wreck"/>
 <tile id="15" class="human">
  <animation>
   <frame tileid="15" duration="500"/>
   <frame tileid="16" duration="500"/>
  </animation>
 </tile>
 <tile id="16" class="human_idle"/>
 <tile id="17" class="human_wreck"/>
</tileset>
