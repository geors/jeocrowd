# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

BASE_GRID_STEP = 0.0005;
LEVEL_MULTIPLIER = 5;
COORDINATE_SEPARATOR = '^';

class window.Tile
    
  constructor: (@level, id...) ->
    @grid = Jeocrowd.grids(@level)
    if id.length == 1
      @id = id[0]
      [@gridLat, @gridLon] = id[0].split COORDINATE_SEPARATOR
      @gridLat = @grid.digitizeCoordinate(parseFloat @gridLat)
      @gridLon = @grid.digitizeCoordinate(parseFloat @gridLon)
    else if id.length == 2
      @id = id[0] + '^' + id[1]
      @gridLat = @grid.digitizeCoordinate(if typeof id[0] == 'string' then parseFloat id[0] else id[0])
      @gridLon = @grid.digitizeCoordinate(if typeof id[1] == 'string' then parseFloat id[1] else id[1])
    @degree = 0
    @points = []
    @className = 'Tile'
  
  getId: ->
    @id
  
  sanitizedId: ->
    @id.replace(/[^0-9A-Za-z]/g, '_')
    
  linkTo: ->
    '<a href="#' + @id + '" class="pan_map_to_href">' + @id + '</a>'
    
  toJSON: (withoutID, withoutPoints) ->
    json = {'id': @id, 'degree': @degree}
    json.points = @points if @points && @points.length > 0
    delete(json.id) if (withoutID)
    delete(json.points) if (withoutPoints)
    json
    
  toSimpleJSON: (key) ->
    json = {}
    json[@id] = this[key]
    json
      
  addPoint: (point) ->
    if @points.indexOf point.url == -1
      @points.push point.url
      @setDegree @degree + 1
      true
    else
      false
        
  setDegree: (degree) ->
    if @grid.hottestTile == null || @grid.hottestTile.degree < degree
      @grid.hottestTile = this 
      $('#hottest_tiles_value').html(@linkTo())
      $('#hottest_tiles_degree_value').text(degree)
    delete(@status) if degree != 0
    @degree = degree
    
  refined: ->
    @degree > 0
  
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

  getBoundingBoxString: ->
    box = @getBoundingBox();
    [box.left, box.bottom, box.right, box.top].join()
  
  getCenter: ->
    box = @getBoundingBox();
    new google.maps.LatLng(box.bottom + this.grid.step() / 2, box.left + this.grid.step() / 2)
  
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
      google.maps.event.addListener(@visual, 'click', Util.createDelegate(this, Tile.prototype.visualClicked));
    if @shouldDisplay()
      @visual.setMap Jeocrowd.map
    else
      @visual.setMap null
      
  drawNeighborhood: ->
    @draw()
    @getNeighbors().each 'draw'
    
  visualClicked: ->
    @grid.selectedTile = this
    $('#selected_tile_value').html(@linkTo())
    $('#selected_tile_degree_value').text(@degree)
    $('#selected_tile_neighbors_value').text(@getNeighbors().size())

    
  highlight: (display) ->
    @visualBounds = @visualBounds || new google.maps.Rectangle({
      bounds: new google.maps.LatLngBounds(
        new google.maps.LatLng(@getBoundingBox().bottom, @getBoundingBox().left),
        new google.maps.LatLng(@getBoundingBox().top, @getBoundingBox().right)
      ),
      fillOpacity: 0,
      zIndex: 20
    })
    @visualBounds.setMap(if display then Jeocrowd.map else null)

    
  highlight2: (display) ->
    @visualCross1 = @visualCross1 || new google.maps.Polygon({
      paths: [
        new google.maps.LatLng(@getBoundingBox().top, @getBoundingBox().left),
        new google.maps.LatLng(@getBoundingBox().bottom, @getBoundingBox().right)
      ],
      strokeOpacity: 0.8,
      strokeWeight: 1,
      fillOpacity: 0,
      zIndex: 20
    })
    @visualCross2 = @visualCross2 || new google.maps.Polygon({
      paths: [
        new google.maps.LatLng(this.getBoundingBox().top, this.getBoundingBox().right),
        new google.maps.LatLng(this.getBoundingBox().bottom, this.getBoundingBox().left)
      ],
      strokeOpacity: 0.8,
      strokeWeight: 1,
      fillOpacity: 0,
      zIndex: 20
    })
    if display
      @visualCross1.setMap Jeocrowd.map
      @visualCross2.setMap Jeocrowd.map
    else
      @visualCross1.setMap null
      @visualCross2.setMap null
    

  undraw: ->
    @visual.setMap(null) if @visual


  getColor: ->
    if @status == 'ignored'
      '#AAAAAA'
    else if @status == 'unknown'
      '#DDDDDD'
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
        @degree / 1000.0
    else
      0.75

  shouldDisplay: ->
    true
  
  #
  # ---- ---- NEIGHBORS ---- ----
  #

  getNeighborIds: ->
    if @neighborIds == undefined
      addMe = @grid.step() + (@grid.step() / 2)
      subMe = @grid.step() / 2
      topLeft      = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon - subMe
      top          = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon     
      topRight     = @grid.digitizeCoordinates @gridLat + addMe,  @gridLon + addMe
      right        = @grid.digitizeCoordinates @gridLat,          @gridLon + addMe
      bottomRight  = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon + addMe
      bottom       = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon
      bottomLeft   = @grid.digitizeCoordinates @gridLat - subMe,  @gridLon - subMe
      left         = @grid.digitizeCoordinates @gridLat,          @gridLon - subMe
      @neighborIds = [topLeft, top, topRight, right, bottomRight, bottom, bottomLeft, left]
    @neighborIds


  getSquareNeighborIds: ->
    if @squareNeighborIds == undefined
      n = @getNeighborIds()
      @squareNeighborIds = [n[1], n[3], n[5], n[7]]
    @squareNeighborIds


  getNeighbors: (force) ->
    @neighbors = new TileCollection()
    @neighbors.copyFrom @getNeighborIds(), @grid.tiles, if force then @grid.level else null
    @neighbors.filter 'refined'           # do not include neighbors with zero degree


  getSquareNeighbors: (force) ->
    @squareNeighbors = new TileCollection()
    @squareNeighbors.copyFrom @getSquareNeighborIds(), @grid.tiles, if force then @grid.level else null
    @squareNeighbors.filter 'refined'     # do not include neighbors with zero degree


  getNeighborCount: ->
    @getNeighbors().size()

  isLoner: ->
    @getNeighbors().size() == 0
    
  willBeRemoved: ->
    @isLoner() || @degree < 0.05 * @grid.hottestTile.degree
    
  
  # 
  # ---- ---- PARENTS, CHILDREN and SIBLINGS ---- ----
  # 
  
  always: ->
    true
  
  atLeastOne: ->
    @getSiblings().size() >= 1

  atLeastTwo: ->
    @getSiblings().size() >= 2

  toParent: (algorithm) ->
    if algorithm.apply this # algorithm used to decide growing up or not, eg atLeastOne, atLeastTwo... etc...
      degree = 0
      points = []
      @getSiblings().each (child) ->
        degree += child.degree;
        points.push point for point in child.points
      aboveGrid = Jeocrowd.grids(@grid.level + 1)
      aboveGrid.addTile aboveGrid.digitizeCoordinates(@gridLat, @gridLon), degree, points
    else
      null
  
  toChildren: (algorithm) ->
    if algorithm.apply this # algorithm used to decide growing down or not, eg always...
      belowGrid = Jeocrowd.grids @grid.level - 1
      belowGrid.addTile childId, -1 for childId in @getChildrenIds(true) # children given -1 as initial degree
    else
      null
  
  getParent: (force) ->
    aboveGrid = Jeocrowd.grids @grid.level + 1
    parentId = aboveGrid.digitizeCoordinates(@gridLat, @gridLon)
    parent = aboveGrid.getTile parentId
    if force && parent == null
      parent = new Tile aboveGrid.level, parentId
    parent
    
  getChildrenIds: (force) ->
    return null if @grid.level == 0
    belowGrid = Jeocrowd.grids @grid.level - 1
    if @allChildrenIds == undefined
      @allChildrenIds = []
      vChild = new Tile belowGrid.level, @gridLat, @gridLon
      (
        [lat, lon] = vChildId.split COORDINATE_SEPARATOR
        hChild = new Tile belowGrid.level, lat, lon
        @allChildrenIds.push hChildId for hChildId in hChild.getHorizontalNeighborIds LEVEL_MULTIPLIER - 1
      ) for vChildId in vChild.getVerticalNeighborIds LEVEL_MULTIPLIER - 1
    @childrenIds = @allChildrenIds.map (id, index, ids) ->
      if belowGrid.getTile(id) || force then id else null
    
  getChildren: (force) ->
    @children = new TileCollection()
    @children.copyFrom @getChildrenIds(force), @grid.tiles, if force then @grid.level else null
    @children
    
  getSiblingsIds: (force) ->
    @getParent(true).getChildrenIds(force)
    
  getSiblings: (force) ->
    @siblings = new TileCollection()
    @siblings.copyFrom @getSiblingsIds(force), @grid.tiles, if force then @grid.level else null
    @siblings
    
  getVerticalNeighborIds: (afar) ->
    @grid.digitizeCoordinates(@gridLat + @grid.step() * i + @grid.step() / 2, @gridLon) for i in [0..afar]
  
  getHorizontalNeighborIds: (afar) ->
    @grid.digitizeCoordinates(@gridLat, @grid.step() * i + @grid.step() / 2 + @gridLon) for i in [0..afar]

  








