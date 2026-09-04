---
name: leetcode-next
description: |
  Use when the user runs /next or /leetcode --next. Reads weak-area data to identify the highest-priority pattern, suggests 2-3 suitable LeetCode problems, then hands off to the leetcode skill once the user picks one.
---

# LeetCode — Next Problem

## Language

Respond entirely in **Traditional Chinese (繁體中文)** — all explanations, suggestions, and status messages.

## Triggers

- `/next`
- `/leetcode --next`

---

## Standard Pattern Library

The following is the canonical set of algorithm patterns used for coverage tracking (ordered by priority — lower index = higher priority for Explore mode):

1. Two Pointers
2. Binary Search
3. Sliding Window (Variable Size)
4. BFS (Breadth-First Search)
5. DFS (Depth-First Search)
6. Backtracking
7. Stack / Monotonic Stack
8. Heap / Priority Queue
9. Trie
10. Union Find
11. Bit Manipulation
12. Prefix Sum
13. Intervals / Merge Intervals
14. Linked List
15. Binary Tree Traversal
16. Graph Traversal

When checking if a weak-areas pattern "covers" a standard pattern, use fuzzy/concept matching:
- "Hash Table + Heap" and "Heap / Priority Queue" → same concept, counts as known
- "Sliding Window (Fixed Size)" or "Sliding Window (Counting)" or "Sliding Window + Hash Table" → all cover "Sliding Window (Variable Size)"
- "Dynamic Programming (Kadane's)" or "Dynamic Programming (1D DP)" → both are DP variants, do NOT map to any standard pattern above (DP is intentionally omitted from the standard list because it is already tracked separately)

---

## Steps

### 1. Read state

- Read `.leetcode/performance/weak-areas.md` (note which patterns have been recorded).
- Read `.leetcode/performance/next-history.md`. If missing or empty, treat `call-count` as 0.
- Read `.leetcode/performance/log.md` before choosing suggestions. Treat every problem number recorded there as already practised, regardless of its result or pattern label. When the log is unavailable, also check `solutions/` for existing solution slugs.

### 2. Update counter

- Increment `call-count` by 1.
- Write it back to `.leetcode/performance/next-history.md` in this format:
  ```
  # Next History
  call-count: <N>
  ```

### 3. Identify unseen patterns

Compare all entries in the Standard Pattern Library against weak-areas.md using the fuzzy matching rules above.
Any standard pattern with zero attempts (not covered by any weak-areas entry) is **unseen**.

### 4. Choose mode

| Condition | Mode |
|-----------|------|
| `weak-areas.md` is empty OR missing | **Explore** |
| `call-count % 5 == 0` AND at least one unseen pattern exists | **Explore** |
| Otherwise | **Reinforce** |

**Explore mode**: Pick the highest-priority unseen pattern from the Standard Pattern Library (lowest index number among unseen patterns).

**Reinforce mode**: Sort all weak-areas patterns by struggle rate descending. Break ties by most recently attempted (earlier date = higher priority). Pick the top pattern.

### 5. Announce the pick

**Explore mode** — tell the user (in Traditional Chinese):
> "你還有 X 個從未練過的演算法類型！這次帶你接觸 **<Pattern>**（第 N 次使用 /next）。"

**Reinforce mode** — tell the user (in Traditional Chinese):
> "根據你的練習紀錄，**<Pattern>** 最需要加強（錯誤率：X%，上次練習：<date>）。"

### 6. Suggest problems

Suggest 2–3 well-known, **not-yet-practised** LeetCode problems for the chosen pattern. Match a candidate to prior work by problem number when available; otherwise compare normalized slugs/titles. Do not re-suggest a practised problem merely because it appears under a different pattern in `weak-areas.md`.

If fewer than two unpractised Blind 75 problems directly fit the selected pattern, say so and offer the closest unpractised Blind 75 problems that reinforce the same broader technique. Only suggest an already-practised problem when explicitly recommending `/leetcode --review`, and label it as a review.

For each, provide:
- Problem number + name
- Difficulty (Easy / Medium / Hard)
- Slug (so the user can construct the URL: `leetcode.com/problems/<slug>/`)
- One-line description of why it represents this pattern well

### 7. Hand off

Once the user provides a URL or picks one of the suggestions, invoke the `leetcode` skill to start the session with `/leetcode <url>`.
