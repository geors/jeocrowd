# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005;
LEVEL_MULTIPLIER = 5;
COORDINATE_SEPARATOR = '^';

class window.Tile
    
  constructor: (@level, id...) ->
    if (id.length == 1)
      @id = id[0]
      [@gridLat, @gridLon] = id[0].split COORDINATE_SEPARATOR
      @gridLat = parseFloat @gridLat
      @gridLon = parseFloat @gridLon
    else if id.length == 2
      @id = id[0] + '^' + id[1]
      @gridLat = parseFloat id[0]
      @gridLon = parseFloat id[1]
    @degree = 0
    @points = []
    
  toJSON: (withoutID) ->
    json = {'id': @id, 'degree': @degree}
    json.points = @points if @points.length > 0
    delete(json.id) if (withoutID)
    json
      
  addPoint: (point) ->
    if @points.indexOf point.url == -1
      @points.push point.url
      @degree++
      true
    else
      false
      
  #
  # ---- ---- NEIGHBORS ---- ----
  #

  # GridCell.prototype.getNeighborIds =
  #   function GridCell_getNeighborIds() {
  #     if (this.neighborIds == null) {
  #       var addMe = this.grid.step + this.grid.step / 2;
  #       var subMe = this.grid.step / 2;
  #       var topLeft      = this.grid.digitizeCoordinates(this.gridLat + addMe, this.gridLon - subMe);
  #       var top          = this.grid.digitizeCoordinates(this.gridLat + addMe, this.gridLon);
  #       var topRight     = this.grid.digitizeCoordinates(this.gridLat + addMe, this.gridLon + addMe);
  #       var right        = this.grid.digitizeCoordinates(this.gridLat, this.gridLon + addMe);
  #       var bottomRight  = this.grid.digitizeCoordinates(this.gridLat - subMe, this.gridLon + addMe);
  #       var bottom       = this.grid.digitizeCoordinates(this.gridLat - subMe, this.gridLon);
  #       var bottomLeft   = this.grid.digitizeCoordinates(this.gridLat - subMe, this.gridLon - subMe);
  #       var left         = this.grid.digitizeCoordinates(this.gridLat, this.gridLon - subMe);
  #       this.neighborIds = [topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left];
  #     }
  # 
  #     return this.neighborIds;
  #   }
  # 
  # 
  # GridCell.prototype.getSquareNeighborIds =
  #   function GridCell_getSquareNeighborIds() {
  #     if (this.squareNeighborIds == null) {
  #       var n = this.getNeighborIds();
  #       this.squareNeighborIds = [n[1], n[3], n[5], n[7]];
  #     }
  # 
  #     return this.squareNeighborIds;
  #   }
  # 
  # 
  # GridCell.prototype.getNeighbors = 
  #   function GridCell_getNeighbors(includeNotInGrid) {
  #     this.neighbors = new CellCollection();
  #     this.neighbors.addMultiple(this.getNeighborIds(), this.grid.cells, includeNotInGrid, this.grid);
  # 
  #     return this.neighbors;
  #   }
  # 
  # 
  # GridCell.prototype.getSquareNeighbors = 
  #   function GridCell_getSquareNeighbors(includeNotInGrid) {
  #     this.neighbors = new CellCollection();
  #     this.neighbors.addMultiple(this.getSquareNeighborIds(), this.grid.cells, includeNotInGrid, this.grid);
  # 
  #     return this.neighbors;
  #   }


  getNeighborCount: ->
    #@getNeighbors().size()
    0
      
  #
  # ---- ---- VISUAL DESIGN ---- ----
  #
  getBoundingBox: ->
    if !@boundingBox
      addMe = @grid.step() + @grid.step() / 2;
      @boundingBox = {
        top:    @grid.digitizeCoordinate(@gridLat + addMe),
        bottom: @gridLat,
        left:   @gridLon,
        right:  @grid.digitizeCoordinate(@gridLon + addMe)
      }
    @boundingBox;

  draw: ->
    if @visual
      @visual.setOptions {
        strokeColor: @getColor(),
        fillColor: @getColor(),
        fillOpacity: @getOpacity()
      }
    else
      pathPoints = [
        new google.maps.LatLng @getBoundingBox().top,     @getBoundingBox().left
        new google.maps.LatLng @getBoundingBox().top,     @getBoundingBox().right
        new google.maps.LatLng @getBoundingBox().bottom,  @getBoundingBox().right
        new google.maps.LatLng @getBoundingBox().bottom,  @getBoundingBox().left
      ]
      @visual = new google.maps.Polygon {
        paths: pathPoints,
        strokeColor: @getColor(),
        strokeOpacity: 0.8,
        strokeWeight: 1,
        fillColor: @getColor(),
        fillOpacity: @getOpacity(),
        zIndex: 10
      }
      #google.maps.event.addListener(@visual, "click", createDelegate(this, this.onVisualCellClick));
    if @shouldDisplay()
      @visual.setMap Jeocrowd.map
    else
      @visual.setMap null

    # 
    # GridCell.prototype.highlight =
    #   function Grid_highlight(display) {
    #     this.visualBounds = this.visualBounds || new google.maps.Rectangle({
    #       bounds: new google.maps.LatLngBounds(
    #         new google.maps.LatLng(this.getBoundingBox().bottom, this.getBoundingBox().left),
    #         new google.maps.LatLng(this.getBoundingBox().top, this.getBoundingBox().right)
    #         ),
    #       fillOpacity: 0,
    #       zIndex: 20
    #     });
    #     this.visualBounds.setMap(display == false ? null : this.grid.application.map);
    #   }
    # 
    # 
    # GridCell.prototype.highlight2 =
    #   function Grid_highlight(display) {
    #     this.visualCross1 = this.visualCross1 || new google.maps.Polygon({
    #       paths: [
    #       new google.maps.LatLng(this.getBoundingBox().top, this.getBoundingBox().left),
    #       new google.maps.LatLng(this.getBoundingBox().bottom, this.getBoundingBox().right)
    #       ],
    #       strokeOpacity: 0.8,
    #       strokeWeight: 1,
    #       fillOpacity: 0,
    #       zIndex: 20
    #     });
    #     this.visualCross2 = this.visualCross2 || new google.maps.Polygon({
    #       paths: [
    #       new google.maps.LatLng(this.getBoundingBox().top, this.getBoundingBox().right),
    #       new google.maps.LatLng(this.getBoundingBox().bottom, this.getBoundingBox().left)
    #       ],
    #       strokeOpacity: 0.8,
    #       strokeWeight: 1,
    #       fillOpacity: 0,
    #       zIndex: 20
    #     });
    #     this.visualCross1.setMap(display == false ? null : this.grid.application.map);
    #     this.visualCross2.setMap(display == false ? null : this.grid.application.map);
    #   }


  undraw: ->
    @visual.setMap(null) if @visual

  getColor: ->
    if @status == 'ignored'
      '#AAAAAA'
    else if Jeocrowd.visibleLayer() == 'degree'
      '#FF0000'
    else
      switch @getNeighborCount()
        when 0 then return '#CCFFFF'
        when 1 then return '#66FFCC'
        when 2 then return '#66FF66'
        when 3 then return '#FFFF66'
        when 4 then return '#FFCC00'
        when 5 then return '#FF9900'
        when 6 then return '#FF3300'
        when 7 then return '#FF0000'
        when 8 then return '#CC0000'
    
  getOpacity: ->
    if @status == 'ignored'
      0.5
    else if Jeocrowd.visibleLayer() == 'degree'
      if @degree > 1000
        1
      else
        @degree / 1000
    else
      0.75

  shouldDisplay: ->
    true