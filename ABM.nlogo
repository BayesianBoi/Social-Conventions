;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Setup
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

extensions [ nw ]

globals [  ;; global variables
  mean-path-length ;; average path length between the nodes
  adopter-size-list
  network-density
  avg-clustering-coef
  avg-degree
  max-deg
  min-deg
  average-degree-minority
  stopping-threshold
]

turtles-own [
  memory ;; List to store the names from the last 9-13 interactions
  current-name ;; Current name preference
  minority-agents
  is-minority
]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Clear functions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


to setup
  clear-all
  reset-ticks
  create-network
  layout
end


to introduce-minority
  let num-minority (round (minority-percentage / 100 * count turtles))

  ; Select agents based on the chosen method
  let selected-agents no-turtles
  if initial-spreader-method = 0 [
    ; Random selection
    set selected-agents n-of num-minority turtles
  ]
  if initial-spreader-method = 1 [
    ; Select based on highest node degree
    set selected-agents max-n-of num-minority turtles [count link-neighbors]
  ]

  ; Introduce minority and calculate average degree
  ask selected-agents [
    set current-name "Name2"
    set color red
    set is-minority true
  ]
  set average-degree-minority mean [count link-neighbors] of selected-agents
    ; Calculate the stopping threshold as half of the initial spreaders' percentage
  set stopping-threshold minority-percentage / 2

end


to update-agent-colors
  ask turtles [
    ifelse current-name = "Name1" [
      set color blue ;; Color for agents following the existing consensus
    ] [
      set color red ;; Color for agents following the new consensus
    ]
  ]
end


;; Create the social network
to create-network
  ;; Generate network based on chosen type
  generate-network

  ;; Calculate network measures
  calculate-network-measures

  introduce-minority

end



to generate-network
    nw:generate-preferential-attachment turtles links number_nodes 2 [
      initialize-turtle
    ]
end




to interact-with [partner]
  ;; Add partner's name to memory
  if length memory >= 13 [ set memory but-first memory ]
  set memory lput [current-name] of partner memory

  ;; Decide new name based on memory
  decide-new-name
end

to decide-new-name
  ; Only non-minority agents consider changing their names
  if not is-minority [
    let probability-name1 0.10 * length (filter [name-item -> name-item = "Name1"] memory)
    let probability-name2 0.06 * length (filter [name-item -> name-item = "Name2"] memory)
    let total-probability probability-name1 + probability-name2

    ; Make a decision based on the relative probabilities
    if total-probability > 0 [
      ifelse random-float total-probability < probability-name1 [
        set current-name "Name1"
      ] [
        set current-name "Name2"
      ]
    ]
  ]
end

to initialize-turtle
  set size 2
  set shape "circle"
  set color blue
  set memory []
  set current-name "Name1"
  set is-minority false ; Initialize as not part of the minority
end

to calculate-network-measures
  ;; Calculate degree, clustering coefficient and eigenvector centrality for each node
  nw:set-context turtles links

  ;; Calculate and display network density
  set network-density (2 * count links) / (count turtles * (count turtles - 1))

  ;; calculate and display average node degree
  set avg-degree sum([count link-neighbors] of turtles) / count turtles

  ;; calculate max node degree
  set max-deg max [count link-neighbors] of turtles

  ;; calculate min node degree
  set min-deg min [count link-neighbors] of turtles


  ;; calculate the mean path length
  let path-lengths nw:mean-path-length
  set mean-path-length path-lengths
  ;; Calculate and display other network measures as per your original code...
end



to go
  if ticks >= 100 [ stop ]

  let total-turtles count turtles
  let turtles-name2 count turtles with [current-name = "Name2"]
  let percentage-name2 (turtles-name2 / total-turtles) * 100

  if (percentage-name2 >= 75) or (percentage-name2 < stopping-threshold) [
    stop
  ]

  ask turtles [
    let partner one-of link-neighbors
    if partner != nobody [
      interact-with partner
    ]
  ]

  update-agent-colors
  tick
end


to layout
   layout-spring turtles links 1 25 3.0
  display
end
