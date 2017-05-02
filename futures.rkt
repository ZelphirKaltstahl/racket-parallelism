#lang racket

#|
;; define 2 lists
(define l1
  (for/list ([i (in-range 20000)])
    (+ (* 2 i) 1)))

(define l2
  (for/list ([i (in-range 20000)])
    (- (* 2 i) 1)))

(define (any-double? l)
    (for/or ([i (in-list l)])
      (for/or ([i2 (in-list l)])
        (= i2 (* 2 i)))))

(define (naive-implementation l1 l2)
  ;; start the actual calculation
  (or (any-double? l1)
      (any-double? l2)))

(displayln "naive:")
(time (naive-implementation l1 l2))

(define (future-implementation l1 l2)
  ;; start the actual calculation
  (let ([myfuture
         ;; a future gets some procedure, which will be wrapped
         (future (lambda () (any-double? l2)))])
    (or (any-double? l1)
        ;; futures run in parallel
        ;; so by making one call a future in the let expression
        ;; and accessing it with touch
        ;; we move the computation to another core
        (touch myfuture))))

(displayln "future paralellism:")
(time (future-implementation l1 l2))
|#

;; However some futures cannot run in parallel safely.
;; For such cases using futures does not improve performance.
;; Example:

#|
(define (mandelbrot iterations x y n)
  (let ([ci (- (/ (* 2.0 y) n) 1.0)]
        [cr (- (/ (* 2.0 x) n) 1.5)])
    (let loop ([i 0] [zr 0.0] [zi 0.0])
      (if (> i iterations)
          i
          (let ([zrq (* zr zr)]
                [ziq (* zi zi)])
            (cond
              [(> (+ zrq ziq) 4.0) i]
              [else (loop (add1 i)
                          (+ (- zrq ziq) cr)
                          (+ (* 2.0 zr zi) ci))]))))))

;; mandelbrot only 1
(time (list (mandelbrot 10000000 62 500 1000)))
;; mandelbrot 4
(time (list (mandelbrot 10000000 62 500 1000)
            (mandelbrot 10000000 62 501 1000)))

(time (let ([a-future (future (lambda () (mandelbrot 10000000 62 501 1000)))])
        (list (mandelbrot 10000000 62 500 1000)
              (touch a-future))))
|#

;; the "evil" thing here are memory allocations for numbers
;; rewritten version with fewer memory allocations:
(require racket/flonum)
(define (mandelbrot iterations x y n)
  (let ([ci (fl- (fl/ (* 2.0 (->fl y)) (->fl n)) 1.0)]
        [cr (fl- (fl/ (* 2.0 (->fl x)) (->fl n)) 1.5)])
    (let loop ([i 0] [zr 0.0] [zi 0.0])
      (if (> i iterations)
          i
          (let ([zrq (fl* zr zr)]
                [ziq (fl* zi zi)])
            (cond
              [(fl> (fl+ zrq ziq) 4.0) i]
              [else (loop (add1 i)
                          (fl+ (fl- zrq ziq) cr)
                          (fl+ (fl* 2.0 (fl* zr zi)) ci))]))))))

(time (list (mandelbrot 100000000 62 501 1000)
            (mandelbrot 100000000 62 502 1000)
            (mandelbrot 100000000 62 503 1000)
            (mandelbrot 100000000 62 504 1000)))

(time (let ([a-future1 (future (lambda () (mandelbrot 100000000 62 501 1000)))]
            [a-future2 (future (lambda () (mandelbrot 100000000 62 502 1000)))]
            [a-future3 (future (lambda () (mandelbrot 100000000 62 503 1000)))]
            [a-future4 (future (lambda () (mandelbrot 100000000 62 504 1000)))])
        (list (touch a-future1)
              (touch a-future2)
              (touch a-future3)
              (touch a-future4))))
