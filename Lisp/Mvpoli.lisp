;;;; 793307 Trovato Gaetano
;;;; 793509 Vivace Antonio
 


(defun flatten (l)
  (cond ((null l) nil)
        ((atom l) (list l))
        (t (loop for a in l appending (flatten a)))))

(defun var-of-helper (x)
  (if (eql 'nil (cdr x))
      (third (car x))
      (list (third (car x)) (var-of-helper (cdr x)))))


;; Ispetioning monomials

(defun monomial-degree (x)
  (third x))

(defun monomial-coefficient (x)
  (second x))

(defun varpowers (x)
    (fourth x))

(defun var-of (x)
  (let ((a (varpowers x)))
    (flatten (var-of-helper a))))

;;; Ispetioning polynomials 

(defun monomials (x)
  (second x))

(defun variables-helper (x)
  (if (not (eql '() x))
      (cons (var-of (car x)) (variables-helper (cdr x)))))


(defun variables (x)
  (sort (remove-duplicates (flatten (variables-helper (second x)))) 
        #'string-lessp ))

(defun coefficients (x)
  (flatten (coefficients-helper (second x))))

(defun coefficients-helper (x)
  (if (not (eql '() x))
      (cons (monomial-coefficient (car x)) (coefficients-helper (cdr x)))))

(defun maxdegree (x)
  (apply 'max (poly-degrees (second x))))

(defun mindegree (x)
  (apply 'min (poly-degrees (second x))))

(defun poly-degrees (x)
  (if (not (eql '() x))
      (cons (monomial-degree (car x)) (poly-degrees (cdr x)))))

;;; Parsing and normalization monomial

(defun as-monomial (x) 
  (cond ((integerp x)
         (list 'm x 0 'nil))
        ((and (atom x) (symbolp x)) 
              (list 'm 1 1 (list 'v 1 x)))
        ((eql (car x) '*) 
         (if (integerp (second x))
             (let ((a (as-monomial-helper (cdr (cdr x)) 0)))         
               (list 'm (second x) (first (last a))
                    (m-norm (butlast a))))
             (let ((a (as-monomial-helper (cdr x) 0)))         
               (list 'm 1 (first (last a))
                     (m-norm (butlast a))))))))


(defun as-monomial-helper (x acc)
  (if (eql 'nil x) 
        (list acc)
      (cond ((and (atom (car x)) (symbolp (car x)))
            (cons (list 'v 1 (car x)) 
                  (as-monomial-helper (cdr x) (+ acc 1)))) 
            (T (cons (list 'v (third (car x)) (second (car x)))
              (as-monomial-helper (cdr x) (+ acc (third (car x)))))))))

(defun m-norm (x)
  (m-normalizer (sort (copy-seq x) 
                            #' string-lessp :key #' third)))

(defun m-normalizer (x)
  (cond ((eql (car x) 'nil) 'nil)
        ((eql (cdr x) 'nil) x)
        ((eql (third (first x)) (third (second x)))
         (let ((a (+ (second (first x)) (second (second x)))))
           (if (eql a 0)
               (m-normalizer (cdr (cdr x)))
             (m-normalizer (cons (list 'v a (third (first x)))
                                 (cdr (cdr x)))))))
        (T (cons (car x) (m-normalizer (cdr x))))))

;; Parsing and normalization polynomials

; A monomial is also a polynomial   
(defun as-polynomial (x)
  (cond ((or (eql x 0) (eql x 'nil))  
         (list 'poly (as-monomial 0)))
        ((eql (car x) '*)
         (let ((a (as-monomial x)))
            (list 'poly (list a))))
        ((eql (car x) 'm)
           (list 'poly (list x)))
        ((eql (car x) '+)
         (let ((a (as-polynomial-helper (cdr x))))
           (list 'poly (p-norm a))))))

(defun as-polynomial-helper (x) 
  (if (eql 'nil (cdr x))
      (list (as-monomial (car x)))
      (cons (as-monomial (car x)) (as-polynomial-helper (cdr x)))))

(defun p-norm (x)
  (p-norm-help (sort (copy-seq x) #'monomials<)))

(defun p-norm-help (x)
  (cond ((eql (car x) 'nil) 'nil)
        ((eql (cdr x) 'nil) x)
        ((and (eql (third (first x)) (third (second x)))
              (equal (varpowers (first x)) (varpowers (second x))))
         (let ((a (first x)) (b (second x)))
           (if (eql (+ (second a) (second b)) 0)
               (p-norm-help (cdr (cdr x)))
             (p-norm-help (cons (list 'm (+ (second a) (second b))
                                 (third a) (fourth a)) 
                           (cdr (cdr x)))))))
        (T (cons (car x) (p-norm-help (cdr x))))))
           

(defun vps< (vps1 vps2)
  (cond ((null vps1)
         (not (null vps2)))
        ((null vps2) nil)
        (t
         (let* ((vp1 (first vps1))
                (vp2 (first vps2))
                (v1 (third vp1))
                (v2 (third vp2))
                (p1 (second vp1))
                (p2 (second vp2)))
           (cond ((and (eq v1 v2) (eq p1 p2))
                  (vps< (rest vps1) (rest vps2)))
                 ((eq v1 v2) (< p1 p2))
                 (t (string< v1 v2)))))))



(defun monomials< (m1 m2)
  (cond ((null m1) (not (null m2)))
        ((null m2) nil)
        (t (let ((td1 (monomial-degree m1))
                 (td2 (monomial-degree m2))
                 (vps1 (varpowers m1))
                 (vps2 (varpowers m2)))
             (if (eq td1 td2)
                 (vps< vps1 vps2)
               (< td1 td2))))))

;; polynomials' operations

;; accepts polynomials and monomials even not structured
(defun polyval (x y)
  (cond ((eql (first x) 'poly)
         (polyval-helper1 x y))
        ((eql (first x) '+)
         (let ((a (as-polynomial x)))
           (polyval-helper1 a y)))
        ((eql (first x) '*)
         (let ((a (as-polynomial (list '+ x))))
           (polyval-helper1 a y)))))

(defun polyval-helper1 (x y)
  (polyval-helper2 (second x) (var-values (variables x) y) 0))

(defun polyval-helper2 (x y acc)
  (if (not (eql (car x) 'nil))
      (let ((a (+ acc (monomialval (car x) y))))
        (polyval-helper2 (cdr x) y a))
      acc))
 

(defun find-val (x y)
  (if (eql (car (car y)) x)
      (cdr (car y))
      (find-val x (cdr y))))
      
(defun monomialval (x y)
  (if (not (eql (second x) 1))
      (* (second x) (monomialval-helper (fourth x) y 1))
      (monomialval-helper (fourth x) y 1)))

(defun monomialval-helper (x y acc)
  (if (not (eql (car x) 'nil))
      (let ((a (car x))
            (b (find-val (third (car x)) y)))
        (if (> (second a) 1)
            (let ((c (* acc (expt b (second a)))))
              (monomialval-helper (cdr x) y c))
            (let ((d (* acc b)))
              (monomialval-helper (cdr x) y d))))
      acc))
          
(defun var-values (x y)
  (if (not (eql (car x) 'nil))
      (cons (cons (car x) (car y)) 
            (var-values (cdr x) (cdr y)))))
  
(defun polyplus (x y)
  (cond ((eql x 0) y)
        ((eql y 0) x)
        ((eql (car x) 'm)
           (polyplus (as-polynomial x) y))
        ((eql (car y) 'm)
           (polyplus x (as-polynomial y)))
        ((eql (car x) '+)
           (polyplus (as-polynomial x) y))
        ((eql (car y) '+)
           (polyplus x (as-polynomial y)))
        ((and (eql 'poly (car x)) (eql 'poly (car y)))
         (let ((c (append (car (cdr x)) (car (cdr y)))))
           (list 'poly (p-norm c))))))
       
(defun polyminus (x y)
   (cond ((eql y 0) x)
         ((eql x 0) 
          (list 'poly (p-sgnchange (car (cdr y)) (- 1))))
         ((eql (car x) 'm)
          (polyminus (as-polynomial x) y))
         ((eql (car y) 'm)
          (polyminus x (as-polynomial y)))
         ((eql (car x) '+)
           (polyminus (as-polynomial x) y))
        ((eql (car y) '+)
           (polyminus x (as-polynomial y)))
         ((and (eql 'poly (car x)) (eql 'poly (car x)))
          (let ((a (append (car (cdr x)) 
                           (p-sgnchange (car (cdr y)) (- 1)))))
            (list 'poly (p-norm a))))))

(defun p-sgnchange (x y)
  (if (not (eql (car x) 'nil))
      (cons (list 'm (* (second (car x)) y) 
                  (third (car x)) (fourth (car x)))
            (p-sgnchange (cdr x) y))))
 
 
(defun polytimes-helper2 (x y)
  (cond ((eql (car y) 'nil) nil)
        (T (let ((a (append (varpowers x) (varpowers (car y))))
              (b (* (monomial-coefficient x) 
                    (monomial-coefficient (car y))))
              (c (+ (monomial-degree x) (monomial-degree (car y)))))
             (if (eql b 0)
                 (list (list 'm 0 0 'nil))
               (cons (list 'm b c (m-norm a)) 
                     (polytimes-helper2 x (cdr y))))))))

(defun polytimes-helper1 (x y)
  (if (eql (car x) 'nil)
      'nil
      (let ((a (polytimes-helper2 (car x) y)))
      (append a (polytimes-helper1 (cdr x) y)))))
 
(defun polytimes (x y)
  (cond ((eql x 1) y)
        ((eql y 1) x)
        ((or (eql x 0) (eql y 0))
         (list 'm 0 0 'nil))
        ((eql (car x) 'm)
           (polytimes (as-polynomial x) y))
        ((eql (car y) 'm)
           (polytimes x (as-polynomial y)))
        ((eql (car x) '+)
           (polytimes (as-polynomial x) y))
        ((eql (car y) '+)
           (polytimes x (as-polynomial y)))
        (T (list 'poly (p-norm (polytimes-helper1 
                             (monomials x)
                             (monomials y)))))))


;;; Checking

(defun is-monomial (m)
  (and (listp m)
       (eq 'm (first m))
       (let ((mtd (monomial-degree m))
             (vps (varpowers m))
             )
         (and (integerp mtd)
              (>= mtd 0)
              (listp vps)
              (every #'is-varpower vps)))))

(defun is-varpower (vp)
  (and (listp vp)
       (eq 'v (first vp))
       (let ((p (second vp))
             (v (third vp))
             )
         (and (integerp p)
              (>= p 0)
              (symbolp v)))))

(defun is-polynomial (p)
  (and (listp p)
       (eq 'poly (first p))
       (let ((ms (monomials p)))
         (and (every #'is-monomial ms)))))

;;printing 

(defun pprint-polynomial (x)
  (pprint-polynomial-helper (second x)))

(defun pprint-polynomial-helper (x)
  (cond ((eql (cdr x) 'nil)
         (pprint-monomial (car x)))
        (T (pprint-monomial (car x))
            (prin1 '+)
            (pprint-polynomial-helper (cdr x)))))

(defun pprint-monomial (x) 
  (if (not (eql (second x) 1)) 
        (prin1 (second x)))
  (if (> (third x) 0)
      (pprint-monomial-helper (fourth x))))

(defun pprint-monomial-helper (x)
  (if (not (eql (car x) 'nil))
      (let ((a (car x)))
        (prin1 (third a))
        (cond ((> (second a) 1)
               (prin1 '^) 
               (prin1 (second a))))
        (pprint-monomial-helper (cdr x)))))
  


