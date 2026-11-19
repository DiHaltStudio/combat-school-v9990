"""Reduce an arcade capture to the colours a B1 screen can hold."""
import numpy as np


def arcade_palette(image, size=16):
    """The image's exact colours reduced to `size` by merging the closest
    pair (weighted by use; the more used colour stays, no averaging, so
    white, red and the shadow stay exact). Black first (pen 0).

    Vectorised: the pair distances are kept in a matrix, so hundreds of
    colours (a filtered sprite) take well under a second."""
    count = {}
    for rgb in image.getdata():
        count[rgb] = count.get(rgb, 0) + 1
    colours = list(count)
    weight = np.array([count[c] for c in colours], dtype=np.float64)
    rgb = np.array(colours, dtype=np.float64)
    alive = np.ones(len(colours), dtype=bool)
    dist = ((rgb[:, None, :] - rgb[None, :, :]) ** 2).sum(axis=2)
    while alive.sum() > size:
        w = np.minimum(weight[:, None], weight[None, :])
        cost = dist * w
        mask = alive[:, None] & alive[None, :]
        np.fill_diagonal(mask, False)
        cost[~mask] = np.inf
        # Same tie order as the pairwise loop: first pair (i < j) in order.
        cost[np.tril_indices(len(colours))] = np.inf
        a, b = np.unravel_index(np.argmin(cost), cost.shape)
        keep, drop = (a, b) if weight[a] >= weight[b] else (b, a)
        weight[keep] += weight[drop]
        alive[drop] = False
    kept = [colours[i] for i in range(len(colours)) if alive[i]]
    total = {colours[i]: weight[i] for i in range(len(colours)) if alive[i]}
    return sorted(kept, key=lambda c: (c != (0, 0, 0), -total[c]))
