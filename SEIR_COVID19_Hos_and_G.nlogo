;******************;
;1 Declare         ;
;******************;
globals[
  susceptibles_  ;the number of susceptible people
  exposeds       ;poeple who carry the virus and not infected
  infecteds_     ;the number of infected people
  recovereds_    ;the number of recovered people
  death_         ;the number of people died
  islolateds
  width          ;;the width of the world
  ;incubation
  HOS
  full?
  l
]

turtles-own[
  age       ;age of the agent
  status    ;0 for susceptible, 1 for exposed, 2 for infected, 3 for recovered
  isolation ;1 for isolate
  incubation
  days      ;expose and insolation days
  masked    ;when wear mask set 1
  flag      ;to check if being asked or not, 1 is aksed by infected, 2 is asked by exposed
  x         ;home X coord
  y         ;home Y coord
  spread?   ;Ture means agent can spread, false means can not spread
  engery    ;Controls agnets go to Groceay
]

patches-own[
  isolation_area
  ;full?
  hos-capacity
  market-capacity
]

;******************;
;2 Initialization  ;
;******************;
to setup
  ca
  reset-ticks

  ;resize-world 0 width 0 width
  create_pop
  create-environment


  ;;one agent gets infected
  ask n-of 1 turtles
  [
    set status 2 ; set infected
    set color red
    set days 0
    set spread? true
  ]

  set susceptibles_ count turtles with [status = 0]
end

;2.1 Create Population
to create_pop
  ;;create agents
  crt population
  [
    set status 0
    set color blue
    set shape "person"

    set spread? true
    ;set in-hos? false

    move-to one-of patches
    set x pxcor
    set y pycor

    move-to one-of patches
    set incubation random-normal 5 3

  ]

  ask turtles [
    if incubation < 0 [set incubation 1]
    ;show incubation
  ]

  ;;set the world size equal to the number of agents
  set width (sqrt population) - 1
end

;2.2 Create environment
to create-environment
  ;hosptial
  ask patches with [pxcor = 49 and pycor = 0]
  [
    set pcolor pink
    set full? false
    set hos-capacity round population * 3 / 1000
    set HOS round hos-capacity
    show round hos-capacity
    ;no body here when initialize
    ask turtles-here [die]
  ]
end


;******************;
;3 Simulation      ;
;******************;
to regular-move
  ask turtles with [spread? != false] [rt random 360 fd 1]
  spread-1
  get-infected
end


to go
  ;;Stop, if no agent is infected
  if count turtles with [status = 2] = 0 [stop]

  ;Limitation on Hospital
  if Limit = True[
    ;check if the hospital is full
    check-hospital

    ifelse Stay = True
    ;;S2, Self quarantine with Limitaion on Hospital
    [
      ifelse ticks < 15
      ;after a while people start stays at home
      [
        regular-move
        ifelse full? = true [regular-move] [go-hospital]
      ]
      ;else starts staying at home and no one can spread the virus
      [
        ask turtles with [isolation != 1][move-to patch x y set spread? false get-infected]
        ifelse full? = true
        [ask turtles with [isolation != 1][move-to patch x y set spread? false]]
        [go-hospital]
      ]
      recover-hos
      recover-reg
    ]

    ;;S 1, move freely with Linitation on Hospital (works)
    [
      regular-move
      ifelse full? = true [regular-move] [go-hospital]
    ]

    recover-reg
    recover-hos
  ]

  ;Not Hospital Limitaions
  if Limit = False[
    ifelse Stay = False
    ;;S3 Partial Free World, Only infectious go to hospital (works)
    [
      ;move
      ask turtles with [spread? != false] [rt random 360 fd 1]
      ;1 Spread the Disease
      spread-1
      ;2, Get Infected by the Disease
      get-infected
      ;3,go to hospital, because we don't know or understan this  disease
      if ticks > 5 [
        go-hospital
      ]
      ;3. Recover of the Disease
      recover-hos
    ]
    ;;S4, Self Quarantine without Limitaion on Hospital (works)
    [
      ifelse ticks > 15[
        ;s stay at home
        ask turtles with [status = 0][move-to patch x y set spread? false]
        ;exposed stay at home
        ask turtles with [status = 1][move-to patch x y set spread? false]
        go-hospital
        get-infected
        recover-hos
      ]
      ;else
      [
        ask turtles [rt random 360 fd 1]
        spread-1
        get-infected
      ]
    ]
  ]

  ;;update the number of each type of agents
  set susceptibles_  count turtles with [status = 0]
  set exposeds       count turtles with [status = 1]
  set infecteds_     count turtles with [status = 2]
  set recovereds_    count turtles with [status = 3]
  ;set islolateds     count turtles with [isolation = 1]
  set death_         population - count turtles

  update-days ;this function is to track how long the disease stay in human's body
  change-color
  abm-do-plot
  tick
end


;3.1.1 Disease Spread Regular Expose and Infected Spread
to spread-1
  ;Infected spread
  ask turtles with [status = 2][
    if spread? = true
    [
      ask turtles in-radius 3 [set flag 1]
    ]
  ]
  ;exposed spread
  ask turtles with [status = 1][
    if spread? = true
    [
      ask turtles in-radius 3 [set flag 1]
    ]
  ]
  ;Change stauts
  ;one person can lead 3 people to change status to 1
  ask n-of 3 turtles with [flag = 1][
    if (status = 0) or (status = 3)[set status 1 set days 0]
  ]
end

;3.2 People Get infected
;;Status change from 1 to 2
to get-infected
  ;only people who are exposed can get infected
  ask turtles with [status = 1][
    if days > incubation ;icubation days
    [set flag 0 set status 2 set days 0 set spread? true]
  ]
end

;3.3 Go to hosptital
to go-hospital
  ;No Limitation
  ifelse Limit = false[
    ask turtles with [status = 2 and spread? = true][
      move-to patch 49 0
      set spread? false
      set isolation 1
      set days 0
    ]
  ]
  ;With Limit
  [
    ;how many beds left in hospital
    ;set l HOS - count turtles-on patch 49 0
    set l HOS - count turtles with [isolation = 1]
    print l
    ;infectious and spreadable agents
    let temp1 count turtles with [status = 2 and spread? = true]
    ;show temp1
    ;1
    if temp1 = 1
    [
      ask turtles with [status = 2 and spread? = true][
        move-to patch 49 0
        set spread? false
        set isolation 1
        set days 0
      ]
    ]
    ;2
    if temp1 = 0 [show 0]
    ;3
    if temp1 > 2
    [
      ask n-of l turtles with [status = 2 and spread? = true][
        move-to patch 49 0
        set spread? false
        set isolation 1
        set days 0
      ]
    ]

    if Stay = True [
      set l HOS - count turtles with [isolation = 1]
      print l
      let temp2 count turtles with [status = 2 and isolation = 0]

      ;1, no infectious
      if temp2 = 0 [show 0]
      ;2, only on ifectiou, only move that one to hospital
      if temp2 = 1
      [
        ask turtles with [status = 2][
          move-to patch 49 0
          set spread? false
          set isolation 1
          set days 0
        ]
      ]
      ;3 if more than one infectious, see how many beds left in hospital and move that amount of agent to hospital
      if temp2 > 2
      [
        ask n-of l turtles with [status = 2 ][
          move-to patch 49 0
          set spread? false
          set isolation 1
          set days 0
        ]
      ]
    ]
  ]

end

;3.3.1 Update Hospital, Check if the hospital is full
to check-hospital
  ask patches with [pcolor = pink][
    let here count turtles-here
    ifelse here >= HOS
    [set full? true print full?]
    [set full? false print full?]
  ]
end


;3.4.1 People Recover in Hospital
to recover-hos
  ;hospital recover
  ask turtles with [isolation = 1][
    ifelse random-float 0.1 < 0.001 * dt
      ;die
      ;[ht set status 4]
      [die]
      ;else
      [if days > 14[
        move-to patch x y; move back to home
        set spread? true
        set isolation 0
        set status 3
        set days 0]]
  ]
end

;3.4.2 People Recover regular
to recover-reg
  ask turtles with [isolation != 1 and status = 2]
  [
    ifelse random-float 0.1 < 0.05 * dt
    ;die
    ;[ht set status 4]
    [die]
    ;else
    [if random-float 1 < RecoveryRate * dt [set status 3 set days 0]]
  ]
end


;*******************;
;4 Update Variables ;
;*******************;

; 4.1 upadted infected date
to update-days
  ask turtles with [status = 1][
    let d days
    set days d + 1
  ]

  ask turtles with [isolation = 1][
    let d days
    set days d + 1
  ]
end

;4.2 change color
to change-color
  ask turtles[
    if status = 0 [set color blue]
    if status = 1 [set color yellow]
    if status = 2 [set color red]
    if status = 3 [set color green]
  ]
end

;4.3 update-global vartable
to update-global

  set death_ population - count turtles
end



;4.4 plot
to abm-do-plot
  ;;plot the numbers of susceptibles, infecteds, recovereds over time

  ;  if plot-pen-exists? "susceptibles" [
  ;    set-current-plot-pen "susceptibles"
  ;    plotxy ticks susceptibles_
  ;  ]

  if plot-pen-exists? "exposeds" [
    set-current-plot-pen "exposeds"
    plotxy ticks exposeds
  ]

  if plot-pen-exists? "infecteds" [
    set-current-plot-pen "infecteds"
    plotxy ticks infecteds_
  ]
  if plot-pen-exists? "recovereds" [
    set-current-plot-pen "recovereds"
    plotxy ticks recovereds_
  ]

  if plot-pen-exists? "deaths" [
    set-current-plot-pen "deaths"
    plotxy ticks death_
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
256
24
692
461
-1
-1
8.57
1
10
1
1
1
0
0
0
1
0
49
0
49
0
0
1
ticks
30.0

BUTTON
14
23
77
56
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
14
61
77
94
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
15
249
188
282
RecoveryRate
RecoveryRate
0
1
0.2
0.01
1
NIL
HORIZONTAL

PLOT
699
24
1048
308
SIR
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"infecteds" 1.0 0 -2674135 true "" ""
"recovereds" 1.0 0 -13840069 true "" ""
"susceptibles" 1.0 0 -13345367 true "" ""
"exposeds" 1.0 0 -1184463 true "" ""
"deaths" 1.0 0 -16777216 true "" ""

BUTTON
83
61
224
94
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
14
288
186
321
dt
dt
0
1
0.01
0.001
1
NIL
HORIZONTAL

SLIDER
15
209
187
242
Population
Population
0
3000
1500.0
100
1
NIL
HORIZONTAL

MONITOR
930
318
987
363
Width
width
17
1
11

SWITCH
16
156
106
189
Stay
Stay
0
1
-1000

TEXTBOX
116
118
259
146
Go to Hospital With Limitation or Not
11
0.0
1

TEXTBOX
117
166
243
184
Self-Quarantine\n
11
0.0
1

MONITOR
701
316
780
361
Population
count turtles
17
1
11

MONITOR
792
389
911
434
Agents in Hospital
count turtles with [status = 2 and isolation = 1]
17
1
11

MONITOR
787
316
857
361
Infecteds
infecteds_
17
1
11

SWITCH
15
114
105
147
Limit
Limit
0
1
-1000

MONITOR
866
316
923
361
Death
death_
17
1
11

MONITOR
703
389
789
434
Hospital Full?
full?
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is an agent-based model (ABM) version of the SIR model.

## HOW IT WORKS

At the beginning, one agent will get infected. During each iteration (dt), an infected agent may infect 3 agents in r of 3. Here, I would like to map the probability of getting infected to the one in the SD model. Therefore, as in the SD model, the infection rate is the infection rate on the entire population. In this ABM, the probability to get infected is equal to the infection rate divided by the probability to be in the same cell, times the change in time. Each infected agent has a probability to recover in each time period, which equals to the recovery rate times the change in time. The equations can be expressed as:

probability that an agent will get infected = infection rate / probability to be in the same cell * change in time

probability that an agent will recovered = recover rate * change in time


## HOW TO USE IT

1. Use the sliders to set the parameters.

2. Press setup to create the agents, randomly distribute them on the landscape, and randomly select the first infected cell.

3. Press go to run the simulation.

The display in the middle shows the agents, green = susceptibles, red = infected, blue = recovered.


## RELATED MODELS

I have built SIR model using three different approaches, including Agent-Based Modeling, Cellular Automata, and Discrete Event Simulation. Also, there is System Dynamics model of SIR available from Shiflet et al. (2014).

The models are posted on my blog: http://geospatialcss.blogspot.com

## CREDITS AND REFERENCES

Shiflet, A. B., & Shiflet, G. W. (2014). Introduction to computational science: modeling and simulation for the sciences. Princeton University Press.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="S1" repetitions="10" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="500"/>
    <exitCondition>count turtles with [status = 2] = 0</exitCondition>
    <metric>susceptibles_</metric>
    <metric>exposeds</metric>
    <metric>infecteds_</metric>
    <metric>recovereds_</metric>
    <metric>death_</metric>
    <enumeratedValueSet variable="RecoveryRate">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Population">
      <value value="1500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Limit">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Stay">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dt">
      <value value="0.01"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
