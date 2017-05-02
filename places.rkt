#lang racket

(require cpuinfo)
(provide main)

(define my-cpuinfo (get-cpuinfo))
(define PLACES_COUNT 4)

(define (any-double? l)
  (for/or ([i (in-list l)])
    (for/or ([i2 (in-list l)])
      (= i2 (* 2 i)))))

(define (make-place)
  (place my-place-channel
         ;; `my-place-channel` is the channel through which we communicate with `my-place`
         ;; stuff in here is evaluated in a new place (different core)

         ;; bind the thing that comes over the channel to `l` (INPUT)
         (define l (place-channel-get my-place-channel))

         ;; do something with `l` (CALCULATION)
         (define l-double? (any-double? l))

         ;; put the result back on the channel (OUTPUT)
         (place-channel-put my-place-channel l-double?)

         ;; all bindings used in here must be available on the top level of this module
         ;; because place lifts the body of it to the top level of the module
         ;; http://docs.racket-lang.org/guide/parallelism.html
         ))

(define ELEMENTS_COUNT 1000000)

(define (main)
  (define p1 (place my-place-channel1
                    (define l (place-channel-get my-place-channel1))
                    (define l-double? (any-double? l))
                    (place-channel-put my-place-channel1 l-double?)))
  (define p2 (place my-place-channel2
                    (define l (place-channel-get my-place-channel2))
                    (define l-double? (any-double? l))
                    (place-channel-put my-place-channel2 l-double?)))
  (define p3 (place my-place-channel3
                    (define l (place-channel-get my-place-channel3))
                    (define l-double? (any-double? l))
                    (place-channel-put my-place-channel3 l-double?)))
  (define p4 (place my-place-channel4
                    (define l (place-channel-get my-place-channel4))
                    (define l-double? (any-double? l))
                    (place-channel-put my-place-channel4 l-double?)))

  (time
   (place-channel-put p1 (stream->list (in-range ELEMENTS_COUNT)))
   (place-channel-put p2 (stream->list (in-range ELEMENTS_COUNT)))
   (place-channel-put p3 (stream->list (in-range ELEMENTS_COUNT)))
   (place-channel-put p4 (stream->list (in-range ELEMENTS_COUNT)))

   (list (place-channel-get p1)
         (place-channel-get p2)
         (place-channel-get p3)
         (place-channel-get p4))))
