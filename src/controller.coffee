# # Controllers
#
OAC.Client.StreamingVideo.namespace 'Controller', (Controller) ->
	#
	# ### relativeCoords
	#
	# Calculates the coordinates of the event relative to the top-left of the currentElement parameter.
	#
	# Parameters:
	#
	# * currentElement - the element relative to which the coordinates should be returned
	# * event - the event whose coordinates should be returned relative to the currentElement
	#
	# Returns:
	# The coordinates of the event relative to the top-left of the currentElement.
	#
	relativeCoords = (currentElement, event) ->
		pos = $(currentElement).offset();
		
		x: event.pageX - pos.left
		y: event.pageY - pos.top
	
	#
	# ## Drag
	#
	# Attaches to an SVG rendering and produces events at the start, middle, and end of a drag. Coordinates
	# are relative to the bound element.
	#
	Controller.namespace "Drag", (Drag) ->
		Drag.initInstance = (args...) ->
			MITHGrid.Controller.Raphael.initInstance "OAC.Client.StreamingVideo.Controller.Drag", args..., (that) ->
				that.applyBindings = (binding) ->
					el = binding.locate('raphael')

					dstart = (x, y, e) ->
						pos = relativeCoords el.node, e
						binding.events.onFocus.fire pos.x, pos.y
					dend = ->
						binding.events.onUnfocus.fire()
					dmid = (x, y) ->
						binding.events.onUpdate.fire x, y
					
					el.drag dmid, dstart, dend

				that.removeBindings = (binding) ->
					el = binding.locate('raphael')
					
					el.undrag
	
	#
	# ## Select
	#
	# Attaches a click handler to an SVG rendering and fires an onSelect event if the rendering is clicked AND
	# the optional `isSelectable` callback returns true.
	#
	# Options:
	#
	# * isSelectable - callback that should return `true` if the onSelect event should fire
	#
	Controller.namespace "Select", (Select) ->
		Select.initInstance = (args...) ->
			MITHGrid.Controller.Raphael.initInstance "OAC.Client.StreamingVideo.Controller.Select", args..., (that) ->
				options = that.options
				isSelectable = options.isSelectable or -> true

				that.applyBindings = (binding) ->
					el = binding.locate("raphael")

					el.click (e) ->
						if isSelectable()
							binding.events.onSelect.fire()
	
	#
	# ## CanvasClickController
	#
	# Listens for all clicks on the canvas. This controller does two things: enables creation of new annotations
	# by firing the onShapeStart, onShapeDrag, and onShapeDone events; enables unselecting the current active annotation
	# by clicking anywhere not on a shape. These need to be teased apart into two different components.
	#
	# Options:
	#
	# * paper - RaphaelSVG canvas object generated by Raphael Presentation
	#
	# * * *
	#
	Controller.namespace "CanvasClickController", (CanvasClickController) ->
		CanvasClickController.initInstance = (args...) ->
			MITHGrid.Controller.initInstance "OAC.Client.StreamingVideo.Controller.CanvasClickController", args..., (that) ->
				options = that.options
				overlay = null

				#
				# ### #applyBindings
				#
				# Create the object passed back to the Presentation
				#
				that.applyBindings = (binding, opts) ->
					renderings = {}
					paper = opts.paper
					
					# **FIXME:** we shouldn't rely on Raphael using SVG
					
					svgWrapper = binding.locate('svgwrapper')
						
					drawOverlay = ->
						removeOverlay()
						overlay = paper.rect(0,0,paper.width,paper.height)
						overlay.toFront()
						overlay.attr
							fill: "#ffffff"
							opacity: 0.01
						$(overlay.node).css
							"pointer-events": "auto"
					
					removeOverlay = ->
						if overlay?
							overlay.unmousedown()
							overlay.unmouseup()
							overlay.unmousemove()
							overlay.attr
								opacity: 0.0
							overlay.remove()
							overlay = null
						uncaptureMouse()
					
					mouseCaptured = false
					
					captureMouse = (handlers) ->
						if !mouseCaptured
							mouseCaptured = true
							MITHGrid.mouse.capture (eType) ->
								if handlers[eType]?
									handlers[eType](this)
					
					uncaptureMouse = ->
						if mouseCaptured
							MITHGrid.mouse.uncapture()
							mouseCaptured = false

					#
					# #### drawShape (private)
					#
					# Using two html elements: container is for
					# registering the offset of the screen (.section-canvas) and
					# the svgEl is for registering mouse clicks on the svg element (svg)
					#
					# Parameters:
					#
					# * container - DOM element that contains the canvas
					# * svgEl - SVG shape element that will have mouse bindings attached to it
					#
					drawShape = (container) ->
						mouseDown = false
						mouseCaptured = false
						topLeft = []
						bottomRight = []
						drawOverlay()

						overlay.unmousedown()
						overlay.unmouseup()
						overlay.unmousemove()
						
						mousedown = (e) ->
							if mouseDown
								return

							pos = relativeCoords overlay.node, e
							x = pos.x
							y = pos.y
							topLeft = [x, y]
							bottomRight = [x, y]
							mouseDown = true
							binding.events.onShapeStart.fire(topLeft)

						mousemove = (e) ->
							if !mouseDown
								return

							pos = relativeCoords overlay.node, e
							x = pos.x
							y = pos.y
							bottomRight = [x, y]
							binding.events.onShapeDrag.fire(bottomRight)

						mouseup = (e) ->
							if !mouseDown
								return

							mouseDown = false

							binding.events.onShapeDone.fire bottomRight
							uncaptureMouse()
							overlay.toFront()
								
						overlay.mousedown mousedown
						overlay.mousemove mousemove
						overlay.mouseup   mouseup
						
						captureMouse
							mousedown: mousedown
							mouseup: mouseup
							mousemove: mousemove
					
					#
					# #### selectShape (private)
					#
					# Creates a binding for the canvas to listen for mousedowns to select a shape instead of drawing a shape.
					#
					# Parameters:
					#
					# * container - HTML element housing the canvas
					#
					selectShape = (container) ->
						drawOverlay()
						
						overlay.unmousedown()
						
						overlay.mousedown ->
							options.application().setActiveAnnotation(undefined)
							activeId = null
							overlay.toBack()
						
						overlay.toBack()
					
					options.application().events.onCurrentModeChange.addListener (mode) ->
						removeOverlay()
						switch options.application().getCurrentModeClass()
							when "shape"  then drawShape svgWrapper
							when "select" then selectShape svgWrapper
							else
								$(svgWrapper).unbind()
					
					binding.toBack = ->
						if overlay?
							overlay.toBack()