(* "Quadtree" doesn't seem to describe one specific data structure. I
   use the term suggestively here. The data structure is my own design
   (though I think obvious). (XXX I found out this is basically a
   kd-tree.) There are two kinds of trees: horizontally- and
   vertically-split. A node in each kind of tree is either empty or a
   point. If it is a point, then it has two children. For
   horizontally-split trees, the left child is a vertically-split tree
   with all points therein being to the west of (or colinear) with the
   point at this node; and the right child with all points (strictly)
   to the east. Vertically-split nodes have horizontal trees as
   children, but of course split into north and south parts. (I'm
   describing a y axis where north trends towards negative infinity,
   as is common in computer graphics. This doesn't affect the client
   interface in any way.)

   This structure doesn't attempt to be smart about the splitting
   direction; it is wasteful when all the points lie on a line, or
   when their horizontal and vertical dispersion is not the same.
   Also, like other naive binary trees, it is not necessarily balanced
   and so certain sequences of insertions will produce trees that have
   linear-time lookups. 

   XXX: It would be easy to generalize this to n-dimensions, though
   keeping the specialized two-dimensional one around is probably good
   for simplicity and efficiency.
*)
functor QuadtreeFn(Q : QUADTREEARG) :> QUADTREE where type xpos = Q.xpos 
                                                  and type ypos = Q.ypos
                                                  and type dist = Q.dist =
struct

    open Q

    datatype 'a horiztree =
        (* left, data, x, y, right *)
        HPoint of 'a verttree * 'a * xpos * ypos * 'a verttree
      | HEmpty
    and 'a verttree =
        (* up, data, x, y, down *)
        VPoint of 'a horiztree * 'a * xpos * ypos * 'a horiztree
      | VEmpty

    (* choice of horiz or vertical is basically arbitrary. *)
    type 'a quadtree = 'a horiztree
    val empty = HEmpty

    fun insert HEmpty a (x, y) = HPoint(VEmpty, a, x, y, VEmpty)
      | insert (HPoint (ll, aa, xx, yy, rr)) a (x, y) =
        if xleq(x, xx)
        then HPoint(vinsert ll a (x, y), aa, xx, yy, rr)
        else HPoint(ll, aa, xx, yy, vinsert rr a (x, y))

    and vinsert VEmpty a (x, y) = VPoint(HEmpty, a, x, y, HEmpty)
      | vinsert (VPoint (uu, aa, xx, yy, dd)) a (x, y) =
        if yleq(y, yy)
        then VPoint(insert uu a (x, y), aa, xx, yy, dd)
        else VPoint(uu, aa, xx, yy, insert dd a (x, y))

    (* The thing that makes this tricky is that the distance d forces us
       to look on both sides of some splits, when the target
       point is close to the split axis. It's real easy to
       test for this case though. *)
    fun lookuppoint HEmpty _ _ = nil
      | lookuppoint (HPoint (ll, aa, xx, yy, rr)) (x : xpos, y : ypos) (d : dist) =
        (* Be a little smart. First do the axis test, which we have to do no
           matter what. If the query point is not close to the axis,
           then we don't need to do the closeness test for the tree
           point, because it will never succeed. *)
        let val dx : xpos = xsub(x, xx)
            fun close () =
                let val res = vlookuppoint ll (x, y) d @ vlookuppoint rr (x, y) d 
                in
                    if dleq (dist (x, y) (xx, yy), d)
                    then (aa, xx, yy) :: res
                    else res
                end
        in
            if xleq(dx, xzero)
            then 
                (* on the left, or colinear *)
                (if dleq(xdist(dx, xzero), d)
                 then close ()
                 else vlookuppoint ll (x, y) d)
            else 
                (* on the right *)
                (if dleq(xdist(dx, xzero), d)
                 then close ()
                 else vlookuppoint rr (x, y) d)
        end

    and vlookuppoint VEmpty _ _ = nil
      | vlookuppoint (VPoint (uu, aa, xx, yy, dd)) (x, y) d =
        let val dy : ypos = ysub(y, yy)
            fun close () =
                let val res = lookuppoint uu (x, y) d @ lookuppoint dd (x, y) d 
                in
                    if dleq (dist (x, y) (xx, yy), d)
                    then (aa, xx, yy) :: res
                    else res
                end
        in
            if yleq(dy, yzero)
            then 
               (* above, or colinear *)
                (if dleq(ydist(dy, yzero), d)
                 then close ()
                 else lookuppoint uu (x, y) d)
            else 
               (* below *)
                (if dleq(ydist(dy, yzero), d)
                 then close ()
                 else lookuppoint dd (x, y) d)
        end

    fun lookup q p d = map #1 (lookuppoint q p d)

    fun map (f : 'a -> 'b) q =
        let
            fun mhoriz HEmpty = HEmpty
              | mhoriz (HPoint (l, a, x, y, r)) = HPoint (mvert l, f a, x, y, mvert r)
            and mvert VEmpty = VEmpty
              | mvert (VPoint (l, a, x, y, r)) = VPoint (mhoriz l, f a, x, y, mhoriz r)
        in
            mhoriz q
        end
end

structure Quadtree = QuadtreeFn(
  type xpos = real
  type ypos = real
  type dist = real
  val xleq : xpos * xpos -> bool = op <=
  val yleq : ypos * ypos -> bool = op <=
  val xsub : xpos * xpos -> xpos = op -
  val ysub : ypos * ypos -> ypos = op -
  val xzero = 0.0
  val yzero = 0.0
  fun dist (x, y) (xx, yy) = 
      Math.sqrt ((x - xx) * (x - xx) + (y - yy) * (y - yy))
  fun xdist (x1, x2) = Real.abs(x1 - x2)
  fun ydist (y1, y2) = Real.abs(y1 - y2)
  val dleq : dist * dist -> bool = op <=)
