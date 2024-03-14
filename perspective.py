def barycentric_coordinates(triangle, point):
    """
    Calculate the barycentric coordinates of a point within a triangle.

    Parameters:
        triangle: List of three tuples representing the vertices of the triangle [(x1, y1), (x2, y2), (x3, y3)].
        point: Tuple representing the coordinates of the point (x, y).

    Returns:
        Tuple representing the barycentric coordinates (u, v, w) of the point.
    """
    # Extract vertices of the triangle
    A, B, C = triangle

    # Calculate vectors
    v0= (B[0] - A[0], B[1] - A[1])
    v1 = (C[0] - A[0], C[1] - A[1])
    v2 = (point[0] - A[0], point[1] - A[1])
    # Compute dot products
    dot00 = v0[0] * v0[0] + v0[1] * v0[1]
    dot01 = v0[0] * v1[0] + v0[1] * v1[1]
    dot02 = v0[0] * v2[0] + v0[1] * v2[1]
    dot11 = v1[0] * v1[0] + v1[1] * v1[1]
    dot12 = v1[0] * v2[0] + v1[1] * v2[1]
    # Compute barycentric coordinates
    inv_denom = (dot00 * dot11 - dot01 * dot01)
    #print(inv_denom)
    v = (dot11 * dot02 - dot01 * dot12) / inv_denom
    #pygame.quit()
    w = (dot00 * dot12 - dot01 * dot02) / inv_denom
    u = 1.0 - w - v

    return u, v, w
def euclidean(a, b):
    return math.sqrt(math.pow(b[0]-a[0], 2)+math.pow(b[1]-a[1], 2)+math.pow(b[2]-a[2], 2))
import pygame, time, math
pygame.init()
#disp = pygame.display.set_mode((800, 600))
#checker = pygame.image.load("check.png").convert_alpha()
#chk_h = checker.get_height()
#chk_w = checker.get_width()
triangle = [[0, 0.0, 0], [0.5, 0.0, 0], [0.0, 0.5, 0]]
print(barycentric_coordinates(triangle, [0, 0.5]))
exit()
camera = [0.5, 1.0, -3.9]
depth = [euclidean(triangle[0], camera), euclidean(triangle[1], camera), euclidean(triangle[2], camera)]
uv = [[0, 0], [0, 1], [1, 0]]
x = euclidean(triangle[1], camera)
attr = [[uv[0][0]/depth[0], uv[0][1]/depth[0], 1/depth[0]],
        [uv[1][0]/depth[1], uv[1][1]/depth[1], 1/depth[1]],
        [uv[2][0]/depth[2], uv[2][1]/depth[2], 1/depth[2]]]
print(attr[1], "\n", attr[2], "\n", attr[0])
bounding = [0, 100, 400, 200]
while True:
    for event in pygame.event.get():
        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_q:
                pygame.quit()
    disp.fill([50, 50, 50])
    for i in range(bounding[3]):
        for j in range(bounding[2]):
            u, v, w = barycentric_coordinates(triangle, [j+bounding[0], i+bounding[1]])
            if u > 1 or u < 0:
                break
            if v > 1 or v < 0:
                break
            if w > 1 or w < 0:
                break
            u_int = u * attr[0][0] + v * attr[1][0] + w * attr[2][0]
            v_int = u * attr[0][1] + v * attr[1][1] + w * attr[2][1]
            d_int = u * attr[0][2] + v * attr[1][2] + w * attr[2][2]
            d_correct = 1 / d_int
            u_int *= d_correct
            v_int *= d_correct
            #depth = (u * depth[0] + v * depth[1] + w * depth_reciprocal[2]) * 140
            #u_int *= depth
            #v_int *= depth
            #print(depth)
            disp.blit(checker, [j+bounding[0], i+bounding[1]], [u_int*chk_w, v_int*chk_h, 1, 1])
    for vertex in triangle:
        pygame.draw.circle(disp, [255, 0, 0], [vertex[0], vertex[1]], 10)
    pygame.display.update()
    time.sleep(1/30)
