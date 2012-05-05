(function() {
  var __slice = Array.prototype.slice;

  MITHGrid.defaults("OAC.Client.StreamingVideo.Demo.Hover", {
    bind: {
      events: {
        onFocus: null,
        onUnfocus: null
      }
    }
  });

  MITHGrid.defaults("OAC.Client.StreamingVideo.Demo.TextControls", {
    events: {
      onDelete: null,
      onEdit: null
    }
  });

  OAC.Client.StreamingVideo.namespace("Demo", function(Demo) {
    Demo.namespace("Hover", function(Hover) {
      return Hover.initInstance = function() {
        var args, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref = MITHGrid.Controller).initInstance.apply(_ref, ["OAC.Client.StreamingVideo.Demo.Hover"].concat(__slice.call(args), [function(that) {
          return that.applyBindings = function(binding) {
            return binding.locate('').hover(binding.events.onFocus.fire, binding.events.onUnfocus.fire);
          };
        }]));
      };
    });
    Demo.namespace("TextControls", function(TextControls) {
      return TextControls.initInstance = function() {
        var args;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return MITHGrid.initInstance.apply(MITHGrid, ["OAC.Client.StreamingVideo.Demo.TextControls"].concat(__slice.call(args), [function(that, container) {
          var options;
          options = that.options;
          if (!(container != null)) container = $("#text-controls");
          that.eventShow = function() {
            return $(container).show();
          };
          that.eventHide = function() {
            return $(container).hide();
          };
          that.eventMove = function(top, right) {
            return $(container).css({
              top: top + "px",
              left: (right - 60) + "px"
            });
          };
          return that.eventHide();
        }]));
      };
    });
    return Demo.namespace("Application", function(Application) {
      return Application.initInstance = function() {
        var args, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        return (_ref = OAC.Client.StreamingVideo.Application).initInstance.apply(_ref, ["OAC.Client.StreamingVideo.Demo.Application"].concat(__slice.call(args), [function(app) {
          return app.ready(function() {
            var annotations, hoverController, textControls;
            annotations = OAC.Client.StreamingVideo.Presentation.AnnotationList.initInstance('#annotation-text', {
              dataView: app.dataView.currentAnnotations,
              lensKey: ['.bodyType'],
              application: app
            });
            hoverController = OAC.Client.StreamingVideo.Demo.Hover.initInstance();
            textControls = OAC.Client.StreamingVideo.Demo.TextControls.initInstance($("#text-controls"));
            app.events.onActiveAnnotationChange.addListener(annotations.eventFocusChange);
            annotations.addLens("Text", function(container, view, model, itemId) {
              var binding, rendering, superFocus, superUnfocus;
              rendering = annotations.initTextLens(container, view, model, itemId);
              binding = hoverController.bind(rendering.el);
              binding.events.onFocus.addListener(function() {
                return app.setActiveAnnotation(itemId);
              });
              binding.events.onUnfocus.addListener(function() {});
              superFocus = rendering.eventFocus;
              superUnfocus = rendering.eventUnfocus;
              rendering.eventFocus = function() {
                superFocus();
                textControls.eventMove($(rendering.el).position().top, $(rendering.el).position().left);
                return textControls.eventShow();
              };
              rendering.eventUnfocus = function() {
                superUnfocus();
                return textControls.eventHide();
              };
              return rendering;
            });
            OAC.Client.StreamingVideo.Component.ModeButton.initInstance("#modeRectangle", {
              mode: "Rectangle",
              application: app
            });
            OAC.Client.StreamingVideo.Component.ModeButton.initInstance("#modeEllipse", {
              mode: "Ellipse",
              application: app
            });
            OAC.Client.StreamingVideo.Component.ModeButton.initInstance("#modeSelect", {
              mode: "Select",
              application: app
            });
            OAC.Client.StreamingVideo.Component.ModeButton.initInstance("#modeWatch", {
              mode: "Watch",
              application: app
            });
            $("#export-button").click(function() {
              var data;
              data = app.exportData();
              return $("#export-text").val(jsl.format.formatJson(JSON.stringify(data)));
            });
            return $("#import-button").click(function() {
              var str;
              str = $("#export-text").val();
              if (str !== "") return app.importData(JSON.parse(str));
            });
          });
        }]));
      };
    });
  });

}).call(this);
