(script-fu-register 
    "script-fu-outline"                                         ;; func name
    "Outline Current Layer..."                                  ;; menu label
    "Creates a simple outline for the current layer"
    "Eric Schneider"                                            ;; copyright notice   
    "2019 Eric Schneider"
    "September 07, 2019 "                                       ;; date created
    "RGBA"                                                      ;; image type that the script works on
    SF-IMAGE        "Image"         0
    SF-DRAWABLE     "Drawable"      0
    SF-ADJUSTMENT   "Border Size"   '(2 1 1000 1 5 0 1)         ;; a spin button
    SF-COLOR        "Color"         '(0 0 0)                    ;; color variable
    SF-TOGGLE       "Merge with Layer?" FALSE                   ;; toggle if the layer should get 
                                                                ;; merged with the outline
)
(script-fu-menu-register "script-fu-outline" "<Image>/Edit")
(define (script-fu-outline inImage inLayer inBorderSize inBorderColor doMergeWitLayer)
  (let* (        
            (inLayerName (car (gimp-item-get-name inLayer)))
            (currentForegroundColor (car (gimp-context-get-foreground)))    ;;get the current foreground 
                                                                            ;;color to reset later
            (borderLayerHeight (+ (car (gimp-drawable-height inLayer)) inBorderSize))
            (borderLayerWidth (+ (car (gimp-drawable-width inLayer)) inBorderSize))
            (borderLayerPosition (+ (car (gimp-image-get-item-position inImage inLayer) ) 1))
            (borderLayerOffsets (gimp-drawable-offsets inLayer))
            (theBorderLayer (car
                              (gimp-layer-new
                                inImage
                                borderLayerWidth
                                borderLayerHeight
                                RGB-IMAGE
                                (string-append "Border Layer of '" inLayerName "'")
                                100
                                LAYER-MODE-NORMAL-LEGACY)))
        )
        (gimp-image-undo-group-start inImage)
        (gimp-selection-none inImage) ;; remove current selection if there is any
        ;;; initialize the border layer
        (gimp-image-add-layer inImage theBorderLayer borderLayerPosition)
        (gimp-layer-set-offsets 
          theBorderLayer 
          (car borderLayerOffsets) 
          (cadr borderLayerOffsets))
        (gimp-layer-add-alpha theBorderLayer)
        (gimp-layer-resize 
          theBorderLayer 
          (+ borderLayerWidth inBorderSize) 
          (+ borderLayerHeight inBorderSize) 
          inBorderSize 
          inBorderSize)
        ;;; Handle the case of the image being smaller than the layer + outline size
        (let*
          (
            (imageHeight (car(gimp-image-height inImage)))
            (imageWidth (car(gimp-image-width inImage)))
            (sizeDiffHeight (- borderLayerHeight imageHeight))
            (sizeDiffWidth (- borderLayerWidth imageWidth))
          )
            (when (< imageHeight borderLayerHeight)
                     (gimp-image-resize 
                       inImage 
                       imageWidth 
                       (+ imageHeight (* sizeDiffHeight 2))
                       0 
                       sizeDiffHeight)
                     (set! imageHeight (car(gimp-image-height inImage))))   ;; if we are increasing the height 
                                                                            ;; we need to save the new size
            (when (< imageWidth borderLayerWidth)
                     (gimp-image-resize 
                       inImage 
                       (+ imageWidth (* sizeDiffWidth 2))
                       imageHeight 
                       sizeDiffWidth 
                       0 ) )
        )
        (plug-in-colortoalpha RUN-NONINTERACTIVE inImage theBorderLayer '(0 0 0))
        ;;; select the outline of the current layer
        (gimp-image-select-item inImage CHANNEL-OP-ADD inLayer)
        (gimp-selection-grow inImage inBorderSize)
        (gimp-context-set-foreground inBorderColor)
        (gimp-edit-bucket-fill 
          theBorderLayer 
          BUCKET-FILL-FG 
          LAYER-MODE-NORMAL-LEGACY 
          100
          0
          TRUE
          0
          0)
        (when (equal? doMergeWitLayer TRUE) 
              (gimp-image-merge-down
                inImage
                inLayer
                CLIP-TO-BOTTOM-LAYER)
        )
        ;;; reset everything that is resettable to the state before
        (gimp-context-set-foreground currentForegroundColor)
        (gimp-selection-none inImage)
        (gimp-displays-flush)
        (gimp-image-undo-group-end inImage)
   )
)
