<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.10" tiledversion="1.10.1" name="tank" tilewidth="14" tileheight="16" tilecount="18" columns="3">
 <image source="../images/spritesheets/tank_basic2.png" width="42" height="96"/>
 <tile id="0" type="simple">
  <properties>
   <property name="cameraSpeed" type="int" value="40"/>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="1250"/>
   <property name="health" type="float" value="1"/>
   <property name="speed" type="int" value="55"/>
   <property name="zoom" type="float" value="3.5"/>
  </properties>
  <animation>
   <frame tileid="0" duration="200"/>
   <frame tileid="1" duration="200"/>
  </animation>
 </tile>
 <tile id="1" type="simple_idle"/>
 <tile id="2" type="simple_wreck"/>
 <tile id="3" type="middle">
  <properties>
   <property name="cameraSpeed" type="int" value="40"/>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="1000"/>
   <property name="health" type="float" value="2"/>
   <property name="speed" type="int" value="50"/>
   <property name="zoom" type="float" value="3"/>
  </properties>
  <animation>
   <frame tileid="3" duration="200"/>
   <frame tileid="4" duration="200"/>
  </animation>
 </tile>
 <tile id="4" type="middle_idle"/>
 <tile id="5" type="middle_wreck"/>
 <tile id="6" type="advanced">
  <properties>
   <property name="cameraSpeed" type="int" value="40"/>
   <property name="damage" type="float" value="1"/>
   <property name="fireDelay" type="int" value="850"/>
   <property name="health" type="float" value="2"/>
   <property name="speed" type="int" value="45"/>
   <property name="zoom" type="float" value="3"/>
  </properties>
  <animation>
   <frame tileid="6" duration="200"/>
   <frame tileid="7" duration="200"/>
  </animation>
 </tile>
 <tile id="7" type="advanced_idle"/>
 <tile id="8" type="advanced_wreck"/>
 <tile id="9" type="heavy">
  <properties>
   <property name="cameraSpeed" type="int" value="35"/>
   <property name="damage" type="float" value="2"/>
   <property name="fireDelay" type="int" value="1500"/>
   <property name="health" type="float" value="3"/>
   <property name="speed" type="int" value="35"/>
   <property name="zoom" type="float" value="2.8"/>
  </properties>
  <animation>
   <frame tileid="9" duration="200"/>
   <frame tileid="10" duration="200"/>
  </animation>
 </tile>
 <tile id="10" type="heavy_idle"/>
 <tile id="11" type="heavy_wreck"/>
 <tile id="12" type="fast">
  <properties>
   <property name="cameraSpeed" type="int" value="60"/>
   <property name="damage" type="float" value="0.25"/>
   <property name="fireDelay" type="int" value="500"/>
   <property name="health" type="float" value="1"/>
   <property name="speed" type="int" value="60"/>
   <property name="zoom" type="float" value="2"/>
  </properties>
  <animation>
   <frame tileid="12" duration="200"/>
   <frame tileid="13" duration="200"/>
  </animation>
 </tile>
 <tile id="13" type="fast_idle"/>
 <tile id="14" type="fast_wreck"/>
 <tile id="15" type="human">
  <animation>
   <frame tileid="15" duration="500"/>
   <frame tileid="16" duration="500"/>
  </animation>
 </tile>
 <tile id="16" type="human_idle"/>
 <tile id="17" type="human_wreck"/>
</tileset>
