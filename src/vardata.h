/******************************************
Copyright (c) 2016, Mate Soos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
***********************************************/

#ifndef __VARDATA_H__
#define __VARDATA_H__

#include "constants.h"
#include "propby.h"
#include "avgcalc.h"

namespace CMSat
{

struct VarData
{
    ///contains the decision level at which the assignment was made.
    uint32_t level = 0;

    uint32_t cancelled = 0;
    uint32_t last_picked = 0;
    uint32_t conflicted = 0;

    //Reason this got propagated. NULL means decision/toplevel
    PropBy reason = PropBy();

    lbool assumption = l_Undef;

    ///Whether var has been eliminated (var-elim, different component, etc.)
    Removed removed = Removed::none;

    ///The preferred polarity of each variable.
    bool polarity = false;
    bool is_bva = false;
    bool added_for_xor = false;
    #ifdef STATS_NEEDED
    uint64_t num_propagated = 0;
    uint64_t num_propagated_pos = 0;
    uint64_t num_decided = 0;
    uint64_t num_decided_pos = 0;

    //picktime data
    uint64_t clid_at_picking = std::numeric_limits<uint64_t>::max();
    #endif
    #if defined(STATS_NEEDED) || defined(FINAL_PREDICTOR)
    uint64_t sumDecisions_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumPropagations_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumConflicts_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumAntecedents_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumAntecedentsLits_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumConflictClauseLits_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumDecisionBasedCl_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumClLBD_at_picktime = std::numeric_limits<uint64_t>::max();
    uint64_t sumClSize_at_picktime = std::numeric_limits<uint64_t>::max();

    uint64_t sumDecisions_below_at_picktime = 0;
    uint64_t sumConflicts_below_at_picktime = 0;
    uint64_t sumAntecedents_below_at_picktime = 0;
    uint64_t sumAntecedentsLits_below_at_picktime = 0;
    uint64_t sumConflictClauseLits_below_at_picktime = 0;
    uint64_t sumDecisionBasedCl_below_at_picktime = 0;
    uint64_t sumClLBD_below_at_picktime = 0;
    uint64_t sumClSize_below_at_picktime = 0;
    #endif

    #ifdef STATS_NEEDED
    uint64_t inside_conflict_clause = 0;
    uint64_t inside_conflict_clause_glue = 0;
    uint64_t inside_conflict_clause_antecedents = 0;

    uint64_t inside_conflict_clause_at_picktime;
    uint64_t inside_conflict_clause_glue_at_picktime;
    uint64_t inside_conflict_clause_antecedents_at_picktime;
    #endif
};

}

#endif //__VARDATA_H__
