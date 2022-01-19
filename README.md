
<!-- README.md is generated from README.Rmd. Please edit that file -->

# impac

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![R-CMD-check](https://github.com/rdinnager/impac/workflows/R-CMD-check/badge.svg)](https://github.com/rdinnager/impac/actions)
<!-- badges: end -->

The goal of `{impac}` is to create packed image mosaics. The main
function `impac`, takes a set of images, or a function that generates
images and packs them into a larger image as tightly as possible,
scaling as necessary, using a greedy algorithm (so don’t expect it to be
fast\!). It is inspired by [this python
script](https://github.com/qnzhou/Mosaic%5D). The main upgrade in this
package is the ability to feed the algorithm a generator function, which
generates an images, as opposed to just a list of pre-existing images
(though it can do this too).

## Installation

You can install the development version from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("rdinnager/impac")
```

## Example

This document and hence the images below are regenerated once a day
automatically. No two will ever be alike.

First we load the packages we need for these examples:

``` r
library(impac)
library(Rvcg)
library(rgl)
library(rphylopic)
```

Next we create an R function to generate an image. In this case, we use
the package `rgl` to plot a simple 3d shape, chosen randomly from a set
of possibilities:

``` r

generate_platonic <- function(i, swidth = 200, sheight = 200, cols = rainbow(100)) {
  
  shape <- sample(c("sphere",
                    "spherical_cap",
                    "tetrahedron",
                    "dodecahedron",
                    "octahedron",
                    "icosahedron",
                    "hexahedron",
                    "cube",
                    "cone"),
                  1)
  
  mesh <- switch (shape,
    sphere = Rvcg::vcgSphere(),
    spherical_cap = Rvcg::vcgSphericalCap(),
    tetrahedron = Rvcg::vcgTetrahedron(),
    dodecahedron = Rvcg::vcgDodecahedron(),
    octahedron = Rvcg::vcgOctahedron(),
    icosahedron = Rvcg::vcgIcosahedron(),
    hexahedron = Rvcg::vcgHexahedron(),
    cube = Rvcg::vcgBox(),
    cone = Rvcg::vcgCone(2, 0, 6)
  )
  
  scales <- c(1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 3, 4)
  mesh <- rgl::scale3d(mesh, 
                       sample(scales, 1),
                       sample(scales, 1),
                       sample(scales, 1))
  
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 0, 1)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 0, 1, 0)
  mesh <- rgl::rotate3d(mesh, runif(1, 0, 2 * pi), 1, 0, 0)
  
  rgl::shade3d(mesh, col = sample(cols, 1),
               specular = "grey")
  
  png_file <- tempfile(fileext = ".png")
  rgl::snapshot3d(filename = png_file, width = swidth, height = sheight,
                  webshot = FALSE)
  rgl::close3d()
  
  im2 <- imager::load.image(png_file)
  im <- imager::imfill(swidth, sheight, val = c(0, 0, 0, 1))
  im[ , , , 1:3] <- im2 
  im[imager::R(im) == 1 & imager::G(im) == 1 & imager::B(im) == 1] <- 0
  
  im  
 
}
```

Now we feed our function to the `impac()` function, which packs the
generated images onto a canvas:

``` r
shapes <- impac(generate_platonic, progress = FALSE, show_every = 0, bg = "white")
imager::save.image(shapes$image, "man/figures/R_gems.png")
```

![Pretty R gems - Packed images of 3d shapes drawn with
{rgl}](man/figures/R_gems.png)

Now let’s pack some Phylopic images\! These are silhouettes of organisms
from the [Phylopic](http://phylopic.org/) project. We will use the
`rphylopic` package to grab a random Phylopic image for packing:

``` r
all_images <- rphylopic::image_list(1, 10000)
all_images <- unlist(all_images)
get_phylopic <- function(i, max_size = 400, isize = 1024) {
  fail <- TRUE
  while(fail) {
    uuid <- sample(all_images, 1)
    pp <- try(rphylopic::image_data(uuid, isize), silent = TRUE)
    if(!inherits(pp, "try-error")) {
      fail <- FALSE
    }
  }
  rot <- aperm(pp$uid, c(2, 1, 3))
  dims <- dim(rot)
  im <- imager::as.cimg(as.vector(rot), dim = c(dims[1], dims[2], 1, dims[3]))
  max_dim <- which.max(dims[1:2])
  other_dim <- (max_size / dims[max_dim]) * dims[1:2][-max_dim]
  new_size <- c(0, 0)
  new_size[max_dim] <- max_size
  new_size[-max_dim] <- other_dim
  im <- imager::resize(im, new_size[1], new_size[2], interpolation_type = 6)
  im <- imager::imchange(im, ~ . < 0, ~ 0)
  im <- imager::imchange(im, ~ . > 1, ~ 1)
  ## this adds custom metadata
  list(im, uuid = uuid)
}
```

Now we run `impac` on our phylopic generating function:

``` r
phylopics <- impac(get_phylopic, progress = FALSE, show_every = 0, bg = "white", min_scale = 0.01)
imager::save.image(phylopics$image, "man/figures/phylopic_a_pack.png")
```

![Packed images of organism silhouettes from
Phylopic](man/figures/phylopic_a_pack.png)

Now we extract the artists who made the above images using the uid of
image.

``` r
image_dat <- lapply(phylopics$meta$uuid, 
                    function(x) {Sys.sleep(2); rphylopic::image_get(x, options = c("credit"))$credit})
```

## Artists whose work is showcased:

Steven Traver, T. Michael Keesey (after C. De Muizon), Matt Crook, Katie
S. Collins, Jack Mayer Wood, Beth Reinke, Rebecca Groom (Based on Photo
by Andreas Trepte), Kamil S. Jaron, Emily Willoughby, T. Michael Keesey,
L. Shyamal, Birgit Lang, Margot Michaud, Nobu Tamura (vectorized by T.
Michael Keesey), Zimices, François Michonneau, Tasman Dixon, Cesar
Julian, Terpsichores, Markus A. Grohme, Anthony Caravaggi, Gabriela
Palomo-Munoz, Mali’o Kodis, photograph by Melissa Frey, Scott Hartman,
Robbie N. Cada (vectorized by T. Michael Keesey), Aline M. Ghilardi,
Tony Ayling (vectorized by T. Michael Keesey), Lukas Panzarin, Roberto
Díaz Sibaja, Kai R. Caspar, Tom Tarrant (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Mali’o Kodis, photograph
by Ching (<http://www.flickr.com/photos/36302473@N03/>), Ferran Sayol,
Rebecca Groom, Jagged Fang Designs, Ludwik Gasiorowski, Benjamint444,
Ignacio Contreras, Dmitry Bogdanov (vectorized by T. Michael Keesey),
Shyamal, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Chris huh, Enoch
Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Aviceda (photo) & T. Michael Keesey, Smokeybjb, Felix
Vaux, (unknown), Tyler Greenfield, Pete Buchholz, Noah Schlottman,
Alexandre Vong, Dean Schnabel, Zsoldos Márton (vectorized by T. Michael
Keesey), Rainer Schoch, Collin Gross, Bruno C. Vellutini, Meliponicultor
Itaymbere, Michelle Site, Gareth Monger, Jan A. Venter, Herbert H. T.
Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey),
wsnaccad, Mali’o Kodis, drawing by Manvir Singh, Sarah Werning, Michele
M Tobias, Maxwell Lefroy (vectorized by T. Michael Keesey), Lily Hughes,
Chris Hay, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Stuart Humphries, Kosta Mumcuoglu (vectorized by T. Michael Keesey),
Melissa Broussard, Tauana J. Cunha, Carlos Cano-Barbacil, Lukasiniho,
Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin, Jaime
Headden, Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Cyril
Matthey-Doret, adapted from Bernard Chaubet, Stephen O’Connor
(vectorized by T. Michael Keesey), Christoph Schomburg, Jose Carlos
Arenas-Monroy, xgirouxb, John Conway, Obsidian Soul (vectorized by T.
Michael Keesey), Chris Jennings (Risiatto), Mr E? (vectorized by T.
Michael Keesey), E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka
(vectorized by T. Michael Keesey), Karl Ragnar Gjertsen (vectorized by
T. Michael Keesey), Maxime Dahirel, Mo Hassan, Michael Scroggie, Martin
R. Smith, Sharon Wegner-Larsen, Ingo Braasch, Christian A. Masnaghetti,
Kanchi Nanjo, Haplochromis (vectorized by T. Michael Keesey), M Kolmann,
Frank Förster (based on a picture by Jerry Kirkhart; modified by T.
Michael Keesey), CNZdenek, Gustav Mützel, Ewald Rübsamen, FJDegrange,
Brad McFeeters (vectorized by T. Michael Keesey), Natasha Vitek,
Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes
(www.carnivorosaustrales.org), Steve Hillebrand/U. S. Fish and Wildlife
Service (source photo), T. Michael Keesey (vectorization), Daniel
Stadtmauer, , Iain Reid, Didier Descouens (vectorized by T. Michael
Keesey), Sergio A. Muñoz-Gómez, Kanako Bessho-Uehara, Joanna Wolfe,
Henry Fairfield Osborn, vectorized by Zimices, Ernst Haeckel (vectorized
by T. Michael Keesey), T. Michael Keesey (after Masteraah), Alexander
Schmidt-Lebuhn, C. Camilo Julián-Caballero, Taenadoman, Tracy A. Heath,
Alex Slavenko, Steven Haddock • Jellywatch.org, Roderic Page and Lois
Page, Noah Schlottman, photo by Carol Cummings, Warren H (photography),
T. Michael Keesey (vectorization), Mali’o Kodis, photograph by Cordell
Expeditions at Cal Academy, Dianne Bray / Museum Victoria (vectorized by
T. Michael Keesey), Julio Garza, FunkMonk, Martien Brand (original
photo), Renato Santos (vector silhouette), Ellen Edmonson and Hugh
Chrisp (illustration) and Timothy J. Bartley (silhouette), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Trond R. Oskars, Cathy, George Edward Lodge, Ron Holmes/U. S.
Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Ricardo N. Martinez & Oscar A. Alcober, Gopal Murali,
Michael B. H. (vectorized by T. Michael Keesey), Dexter R. Mardis,
Mariana Ruiz Villarreal (modified by T. Michael Keesey), Robert Gay,
Tyler McCraney, Luis Cunha, Nobu Tamura (vectorized by A. Verrière),
Fritz Geller-Grimm (vectorized by T. Michael Keesey), Dr. Thomas G.
Barnes, USFWS, Mason McNair, Filip em, Allison Pease, Darren Naish
(vectorized by T. Michael Keesey), T. Michael Keesey (after Mauricio
Antón), Lisa Byrne, Scott Hartman (modified by T. Michael Keesey), Yan
Wong, Stemonitis (photography) and T. Michael Keesey (vectorization),
Matus Valach, James Neenan, Remes K, Ortega F, Fierro I, Joger U, Kosma
R, et al., Saguaro Pictures (source photo) and T. Michael Keesey, Darren
Naish (vectorize by T. Michael Keesey), T. Michael Keesey (vector) and
Stuart Halliday (photograph), Brian Swartz (vectorized by T. Michael
Keesey), T. Michael Keesey (after Heinrich Harder), Richard Parker
(vectorized by T. Michael Keesey), Andreas Hejnol, Caleb M. Brown,
Peileppe, Rene Martin, FunkMonk \[Michael B.H.\] (modified by T. Michael
Keesey), Mathilde Cordellier, Noah Schlottman, photo by Casey Dunn,
Chase Brownstein, Dmitry Bogdanov, Jennifer Trimble, Arthur S. Brum,
S.Martini, Maija Karala, Tony Ayling, Benjamin Monod-Broca, Davidson
Sodré, Ghedoghedo (vectorized by T. Michael Keesey), Todd Marshall,
vectorized by Zimices, Ellen Edmonson and Hugh Chrisp (vectorized by T.
Michael Keesey), Matt Martyniuk, Lankester Edwin Ray (vectorized by T.
Michael Keesey), Christine Axon, Mathew Wedel, Nobu Tamura, Philip
Chalmers (vectorized by T. Michael Keesey), Matt Martyniuk (vectorized
by T. Michael Keesey), Steven Blackwood

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                             |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    384.079545 |    459.414173 | Steven Traver                                                                                                                                                      |
|   2 |    747.043538 |     37.577114 | T. Michael Keesey (after C. De Muizon)                                                                                                                             |
|   3 |    853.366644 |    715.847639 | Matt Crook                                                                                                                                                         |
|   4 |     76.312721 |     43.555448 | Katie S. Collins                                                                                                                                                   |
|   5 |     82.575403 |    690.849145 | Jack Mayer Wood                                                                                                                                                    |
|   6 |    555.856651 |     65.954444 | Beth Reinke                                                                                                                                                        |
|   7 |    608.983791 |    702.639423 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                                   |
|   8 |    919.493520 |    441.982482 | Kamil S. Jaron                                                                                                                                                     |
|   9 |    496.909463 |    716.527103 | Emily Willoughby                                                                                                                                                   |
|  10 |    836.768723 |    637.499125 | T. Michael Keesey                                                                                                                                                  |
|  11 |    741.756482 |    590.315863 | L. Shyamal                                                                                                                                                         |
|  12 |    337.849081 |    689.725178 | NA                                                                                                                                                                 |
|  13 |    148.660617 |    222.631610 | Birgit Lang                                                                                                                                                        |
|  14 |     61.414181 |    465.549644 | Margot Michaud                                                                                                                                                     |
|  15 |    769.253505 |    310.764479 | NA                                                                                                                                                                 |
|  16 |    220.123798 |     34.305693 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  17 |    893.851393 |    341.490800 | NA                                                                                                                                                                 |
|  18 |    657.621951 |    528.280234 | Zimices                                                                                                                                                            |
|  19 |    471.495775 |    309.981773 | Matt Crook                                                                                                                                                         |
|  20 |    152.669998 |    589.204468 | François Michonneau                                                                                                                                                |
|  21 |    585.821250 |    422.832372 | Tasman Dixon                                                                                                                                                       |
|  22 |    931.133206 |    176.635743 | NA                                                                                                                                                                 |
|  23 |    164.368475 |    725.071937 | Cesar Julian                                                                                                                                                       |
|  24 |    786.282315 |    154.986072 | Matt Crook                                                                                                                                                         |
|  25 |    434.282739 |    544.444634 | Zimices                                                                                                                                                            |
|  26 |    258.659126 |    365.731180 | Terpsichores                                                                                                                                                       |
|  27 |     76.899332 |    343.551697 | Markus A. Grohme                                                                                                                                                   |
|  28 |    261.007925 |    536.344994 | Margot Michaud                                                                                                                                                     |
|  29 |    637.127164 |    145.034654 | Anthony Caravaggi                                                                                                                                                  |
|  30 |    365.823765 |    101.327544 | Gabriela Palomo-Munoz                                                                                                                                              |
|  31 |    962.616419 |    611.820871 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                           |
|  32 |    667.093258 |    649.872115 | Scott Hartman                                                                                                                                                      |
|  33 |    412.913348 |    170.781280 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                   |
|  34 |    744.162779 |    408.021770 | Aline M. Ghilardi                                                                                                                                                  |
|  35 |    357.092274 |    238.295325 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                      |
|  36 |    933.205952 |     49.450238 | Gabriela Palomo-Munoz                                                                                                                                              |
|  37 |    853.750701 |    507.367320 | Lukas Panzarin                                                                                                                                                     |
|  38 |    540.677484 |    126.600713 | Scott Hartman                                                                                                                                                      |
|  39 |    787.433633 |    237.278271 | Roberto Díaz Sibaja                                                                                                                                                |
|  40 |    415.522848 |     52.976468 | Zimices                                                                                                                                                            |
|  41 |    693.097026 |    753.452563 | Kai R. Caspar                                                                                                                                                      |
|  42 |    631.413670 |    296.642827 | Matt Crook                                                                                                                                                         |
|  43 |    191.045440 |    513.028692 | NA                                                                                                                                                                 |
|  44 |    346.086755 |    343.845361 | L. Shyamal                                                                                                                                                         |
|  45 |    943.216472 |    734.847325 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
|  46 |    264.194899 |    124.763280 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                   |
|  47 |     98.385713 |    409.905015 | Ferran Sayol                                                                                                                                                       |
|  48 |    778.458774 |    710.749836 | Rebecca Groom                                                                                                                                                      |
|  49 |    917.808475 |    291.852695 | Tasman Dixon                                                                                                                                                       |
|  50 |    493.533062 |    772.041293 | Markus A. Grohme                                                                                                                                                   |
|  51 |    181.348830 |    630.334242 | Jagged Fang Designs                                                                                                                                                |
|  52 |    388.780103 |    743.357272 | Ludwik Gasiorowski                                                                                                                                                 |
|  53 |     85.061081 |    236.325484 | T. Michael Keesey                                                                                                                                                  |
|  54 |    466.578686 |    443.740713 | Margot Michaud                                                                                                                                                     |
|  55 |    811.968569 |    403.153986 | Benjamint444                                                                                                                                                       |
|  56 |     72.869127 |    634.037430 | Ignacio Contreras                                                                                                                                                  |
|  57 |    456.434647 |    640.475128 | Margot Michaud                                                                                                                                                     |
|  58 |     74.446436 |    554.942518 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
|  59 |    120.774159 |    128.994449 | Scott Hartman                                                                                                                                                      |
|  60 |    784.714749 |    475.405893 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
|  61 |    829.536479 |     77.829029 | NA                                                                                                                                                                 |
|  62 |    808.551346 |    563.554474 | Shyamal                                                                                                                                                            |
|  63 |    295.832251 |    773.908118 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                              |
|  64 |    953.959170 |    538.206089 | Beth Reinke                                                                                                                                                        |
|  65 |    599.226994 |    596.735650 | Zimices                                                                                                                                                            |
|  66 |     35.590480 |    169.415582 | Ferran Sayol                                                                                                                                                       |
|  67 |    178.179553 |    297.442716 | Chris huh                                                                                                                                                          |
|  68 |     83.498295 |    766.481736 | Enoch Joseph Wetsy (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  69 |    114.778730 |    773.327274 | Scott Hartman                                                                                                                                                      |
|  70 |    843.169235 |    160.984952 | Matt Crook                                                                                                                                                         |
|  71 |    354.309938 |    615.761661 | Aviceda (photo) & T. Michael Keesey                                                                                                                                |
|  72 |    747.146885 |    270.856432 | Smokeybjb                                                                                                                                                          |
|  73 |    623.893396 |    374.209148 | Felix Vaux                                                                                                                                                         |
|  74 |    592.554644 |    787.923615 | (unknown)                                                                                                                                                          |
|  75 |    206.176667 |    392.757599 | Felix Vaux                                                                                                                                                         |
|  76 |    117.124597 |    503.562648 | NA                                                                                                                                                                 |
|  77 |    145.882772 |    698.791221 | Tyler Greenfield                                                                                                                                                   |
|  78 |    128.035559 |     94.459992 | Pete Buchholz                                                                                                                                                      |
|  79 |    679.574097 |    602.087375 | Noah Schlottman                                                                                                                                                    |
|  80 |    969.987524 |    319.024590 | Alexandre Vong                                                                                                                                                     |
|  81 |    270.036861 |    302.078100 | Dean Schnabel                                                                                                                                                      |
|  82 |    658.224207 |    100.694995 | NA                                                                                                                                                                 |
|  83 |    306.621594 |    645.613084 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                   |
|  84 |    986.836973 |    392.598226 | Steven Traver                                                                                                                                                      |
|  85 |    678.941221 |     65.272756 | Gabriela Palomo-Munoz                                                                                                                                              |
|  86 |    564.361997 |    217.934621 | Zimices                                                                                                                                                            |
|  87 |    860.232735 |    758.037834 | Rainer Schoch                                                                                                                                                      |
|  88 |    271.043469 |    224.289381 | Gabriela Palomo-Munoz                                                                                                                                              |
|  89 |    788.261324 |    353.214366 | Collin Gross                                                                                                                                                       |
|  90 |    247.310159 |    731.593191 | Bruno C. Vellutini                                                                                                                                                 |
|  91 |     34.872635 |    277.080211 | Meliponicultor Itaymbere                                                                                                                                           |
|  92 |    554.803367 |    524.419784 | NA                                                                                                                                                                 |
|  93 |    541.646335 |    401.426153 | Emily Willoughby                                                                                                                                                   |
|  94 |    922.797012 |    558.612076 | Michelle Site                                                                                                                                                      |
|  95 |    438.860571 |    270.897087 | Scott Hartman                                                                                                                                                      |
|  96 |    441.554691 |    125.729543 | NA                                                                                                                                                                 |
|  97 |    908.290759 |    714.080695 | Gareth Monger                                                                                                                                                      |
|  98 |    301.925562 |    182.940785 | Margot Michaud                                                                                                                                                     |
|  99 |    992.281979 |    474.763039 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                |
| 100 |    643.172573 |     24.941197 | Scott Hartman                                                                                                                                                      |
| 101 |    154.458457 |    344.550468 | wsnaccad                                                                                                                                                           |
| 102 |    884.631008 |    382.903504 | Zimices                                                                                                                                                            |
| 103 |    637.560499 |    482.175309 | NA                                                                                                                                                                 |
| 104 |    697.432600 |    688.635131 | Mali’o Kodis, drawing by Manvir Singh                                                                                                                              |
| 105 |     31.630438 |    731.188535 | Sarah Werning                                                                                                                                                      |
| 106 |    834.481607 |      9.550471 | Jagged Fang Designs                                                                                                                                                |
| 107 |    829.703587 |     41.426258 | Steven Traver                                                                                                                                                      |
| 108 |    912.185656 |    614.955311 | Michele M Tobias                                                                                                                                                   |
| 109 |    713.294734 |    371.494457 | Michelle Site                                                                                                                                                      |
| 110 |    612.653806 |    236.894047 | Felix Vaux                                                                                                                                                         |
| 111 |    744.898129 |    456.607947 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                   |
| 112 |    152.918589 |    451.343303 | Matt Crook                                                                                                                                                         |
| 113 |    643.772479 |    620.215321 | Lily Hughes                                                                                                                                                        |
| 114 |    548.750511 |    747.127034 | Chris Hay                                                                                                                                                          |
| 115 |    985.252845 |    187.359212 | Zimices                                                                                                                                                            |
| 116 |     48.327559 |    600.006802 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                        |
| 117 |    808.217666 |    784.221320 | Roberto Díaz Sibaja                                                                                                                                                |
| 118 |    131.783741 |    217.602630 | Tasman Dixon                                                                                                                                                       |
| 119 |    631.671923 |    221.549915 | Stuart Humphries                                                                                                                                                   |
| 120 |    772.338324 |    648.617256 | Kosta Mumcuoglu (vectorized by T. Michael Keesey)                                                                                                                  |
| 121 |    266.801432 |    708.724917 | L. Shyamal                                                                                                                                                         |
| 122 |    576.259846 |    726.140317 | NA                                                                                                                                                                 |
| 123 |    502.870717 |    100.265945 | Melissa Broussard                                                                                                                                                  |
| 124 |    531.386453 |    673.067193 | Tauana J. Cunha                                                                                                                                                    |
| 125 |    789.596656 |    738.242278 | Rebecca Groom                                                                                                                                                      |
| 126 |    401.623759 |    642.558438 | Carlos Cano-Barbacil                                                                                                                                               |
| 127 |    953.144599 |    496.310683 | Gabriela Palomo-Munoz                                                                                                                                              |
| 128 |    290.447752 |    386.914752 | Lukasiniho                                                                                                                                                         |
| 129 |     19.746125 |    525.756942 | Leon P. A. M. Claessens, Patrick M. O’Connor, David M. Unwin                                                                                                       |
| 130 |    408.691274 |    284.423088 | Jaime Headden                                                                                                                                                      |
| 131 |    313.045973 |    521.612204 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                            |
| 132 |    740.179046 |    786.278432 | T. Michael Keesey                                                                                                                                                  |
| 133 |     61.157916 |    380.102605 | Scott Hartman                                                                                                                                                      |
| 134 |    968.739811 |    788.357095 | T. Michael Keesey                                                                                                                                                  |
| 135 |    154.100363 |    551.869859 | Cyril Matthey-Doret, adapted from Bernard Chaubet                                                                                                                  |
| 136 |    388.275705 |    385.937663 | L. Shyamal                                                                                                                                                         |
| 137 |    284.865401 |    458.097867 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                 |
| 138 |    619.806839 |    104.748550 | Ferran Sayol                                                                                                                                                       |
| 139 |    319.551828 |    570.300436 | Zimices                                                                                                                                                            |
| 140 |    320.915506 |    163.853803 | Rebecca Groom                                                                                                                                                      |
| 141 |    295.540676 |    736.817190 | Christoph Schomburg                                                                                                                                                |
| 142 |    542.056673 |    160.641462 | NA                                                                                                                                                                 |
| 143 |    990.245712 |    248.779175 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 144 |    712.252629 |    288.559154 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 145 |    996.381951 |     95.377059 | Matt Crook                                                                                                                                                         |
| 146 |    778.461370 |    515.783428 | Markus A. Grohme                                                                                                                                                   |
| 147 |    399.568322 |     17.668825 | xgirouxb                                                                                                                                                           |
| 148 |   1003.435768 |     37.199252 | Margot Michaud                                                                                                                                                     |
| 149 |    663.089431 |    425.377092 | Matt Crook                                                                                                                                                         |
| 150 |    158.612094 |    753.843065 | John Conway                                                                                                                                                        |
| 151 |    491.369620 |    417.443894 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                    |
| 152 |    376.431905 |    417.221211 | Alexandre Vong                                                                                                                                                     |
| 153 |     45.008933 |    663.090076 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 154 |    299.894441 |    708.778275 | Christoph Schomburg                                                                                                                                                |
| 155 |    482.320089 |    178.334811 | Michelle Site                                                                                                                                                      |
| 156 |   1009.318748 |    280.130985 | Margot Michaud                                                                                                                                                     |
| 157 |     34.242916 |     97.544371 | Gareth Monger                                                                                                                                                      |
| 158 |     67.366788 |    590.566448 | Jagged Fang Designs                                                                                                                                                |
| 159 |    878.490233 |    642.610613 | Chris Jennings (Risiatto)                                                                                                                                          |
| 160 |    585.112882 |    767.765202 | Margot Michaud                                                                                                                                                     |
| 161 |    309.591747 |    412.734098 | Rebecca Groom                                                                                                                                                      |
| 162 |    921.238194 |    694.509270 | Jack Mayer Wood                                                                                                                                                    |
| 163 |    673.212008 |    445.710307 | Matt Crook                                                                                                                                                         |
| 164 |    743.599407 |    665.317797 | Zimices                                                                                                                                                            |
| 165 |    479.418007 |     60.110350 | Zimices                                                                                                                                                            |
| 166 |    556.186099 |    478.213076 | Matt Crook                                                                                                                                                         |
| 167 |    964.330807 |    227.980490 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 168 |    205.820187 |    140.728801 | Mr E? (vectorized by T. Michael Keesey)                                                                                                                            |
| 169 |   1004.240883 |    150.199438 | L. Shyamal                                                                                                                                                         |
| 170 |    313.641417 |     36.999226 | E. J. Van Nieukerken, A. Laštuvka, and Z. Laštuvka (vectorized by T. Michael Keesey)                                                                               |
| 171 |    728.202801 |    488.686929 | Gabriela Palomo-Munoz                                                                                                                                              |
| 172 |    515.822774 |     23.517132 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                             |
| 173 |    319.354444 |    553.579312 | Maxime Dahirel                                                                                                                                                     |
| 174 |    238.759434 |    683.829588 | Mo Hassan                                                                                                                                                          |
| 175 |    582.708183 |    364.182400 | Michael Scroggie                                                                                                                                                   |
| 176 |    174.014832 |    657.069391 | Jagged Fang Designs                                                                                                                                                |
| 177 |    887.656031 |    586.808341 | Martin R. Smith                                                                                                                                                    |
| 178 |    451.142551 |    210.772182 | Cesar Julian                                                                                                                                                       |
| 179 |     16.493029 |     15.285807 | Ferran Sayol                                                                                                                                                       |
| 180 |    299.791089 |     14.324423 | Matt Crook                                                                                                                                                         |
| 181 |    274.024422 |    274.560480 | Steven Traver                                                                                                                                                      |
| 182 |    311.011686 |    135.198469 | Sharon Wegner-Larsen                                                                                                                                               |
| 183 |    949.549277 |    103.903886 | Gareth Monger                                                                                                                                                      |
| 184 |    185.730426 |      9.098518 | Ingo Braasch                                                                                                                                                       |
| 185 |    385.294766 |     25.187421 | Chris huh                                                                                                                                                          |
| 186 |    517.520696 |     20.049855 | Christian A. Masnaghetti                                                                                                                                           |
| 187 |    810.382865 |    265.172571 | Kanchi Nanjo                                                                                                                                                       |
| 188 |    104.628894 |    370.906240 | Chris Jennings (Risiatto)                                                                                                                                          |
| 189 |    467.496075 |    751.974477 | Gabriela Palomo-Munoz                                                                                                                                              |
| 190 |    752.176319 |    103.509634 | L. Shyamal                                                                                                                                                         |
| 191 |    262.860075 |    664.647471 | T. Michael Keesey                                                                                                                                                  |
| 192 |    197.211025 |    668.918661 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                     |
| 193 |    715.680855 |    462.802128 | M Kolmann                                                                                                                                                          |
| 194 |    860.109268 |    263.415373 | NA                                                                                                                                                                 |
| 195 |    211.260420 |    777.885714 | Frank Förster (based on a picture by Jerry Kirkhart; modified by T. Michael Keesey)                                                                                |
| 196 |    533.018220 |    617.407319 | Matt Crook                                                                                                                                                         |
| 197 |    661.424139 |    696.325830 | Zimices                                                                                                                                                            |
| 198 |    511.781370 |    486.680916 | Zimices                                                                                                                                                            |
| 199 |    857.758910 |    421.470272 | CNZdenek                                                                                                                                                           |
| 200 |     97.046117 |    316.469013 | Gustav Mützel                                                                                                                                                      |
| 201 |    480.195159 |    594.120529 | Birgit Lang                                                                                                                                                        |
| 202 |    693.290224 |    346.945782 | T. Michael Keesey                                                                                                                                                  |
| 203 |    584.797593 |     25.625079 | Kamil S. Jaron                                                                                                                                                     |
| 204 |    308.702971 |    328.536759 | Ferran Sayol                                                                                                                                                       |
| 205 |     45.369524 |    117.133123 | Ewald Rübsamen                                                                                                                                                     |
| 206 |     62.448855 |    428.412569 | Matt Crook                                                                                                                                                         |
| 207 |    780.368734 |    578.543718 | FJDegrange                                                                                                                                                         |
| 208 |    385.185113 |    575.080531 | Gareth Monger                                                                                                                                                      |
| 209 |    514.436291 |    168.193099 | Birgit Lang                                                                                                                                                        |
| 210 |    651.700508 |     79.660241 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                   |
| 211 |    970.707127 |    360.271221 | Natasha Vitek                                                                                                                                                      |
| 212 |    950.326348 |    374.326764 | M Kolmann                                                                                                                                                          |
| 213 |    311.951745 |    462.956965 | Ferran Sayol                                                                                                                                                       |
| 214 |    993.593402 |    200.634481 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                       |
| 215 |    298.870399 |    669.580330 | Chris huh                                                                                                                                                          |
| 216 |    911.259417 |    238.324624 | Jaime Headden                                                                                                                                                      |
| 217 |    285.042912 |    494.047286 | Gareth Monger                                                                                                                                                      |
| 218 |     12.872908 |    754.945552 | Emily Willoughby                                                                                                                                                   |
| 219 |    433.831972 |    241.958813 | Zimices                                                                                                                                                            |
| 220 |    153.813310 |     23.082904 | T. Michael Keesey                                                                                                                                                  |
| 221 |    154.589285 |    149.158013 | Gareth Monger                                                                                                                                                      |
| 222 |    862.578349 |    198.348368 | Michelle Site                                                                                                                                                      |
| 223 |    855.106116 |    468.043893 | Kai R. Caspar                                                                                                                                                      |
| 224 |    764.003094 |    772.841727 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                 |
| 225 |    601.746468 |     41.113247 | Felix Vaux                                                                                                                                                         |
| 226 |    586.815761 |    639.341810 | Scott Hartman                                                                                                                                                      |
| 227 |    526.367606 |    201.010439 | Dean Schnabel                                                                                                                                                      |
| 228 |     25.577426 |    207.340267 | NA                                                                                                                                                                 |
| 229 |    882.254549 |    196.757327 | Daniel Stadtmauer                                                                                                                                                  |
| 230 |    966.692669 |    129.517580 |                                                                                                                                                                    |
| 231 |    580.535366 |     11.041861 | Zimices                                                                                                                                                            |
| 232 |    776.255144 |    462.448415 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 233 |    563.576639 |     99.073354 | Ignacio Contreras                                                                                                                                                  |
| 234 |    404.892114 |    277.983510 | Iain Reid                                                                                                                                                          |
| 235 |    726.428782 |    523.871759 | Chris huh                                                                                                                                                          |
| 236 |    162.203650 |    415.105814 | Terpsichores                                                                                                                                                       |
| 237 |    655.492039 |    247.152987 | Zimices                                                                                                                                                            |
| 238 |    848.297368 |     62.847720 | Birgit Lang                                                                                                                                                        |
| 239 |    250.063870 |    646.827182 | Roberto Díaz Sibaja                                                                                                                                                |
| 240 |     15.626350 |    400.104582 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 241 |    925.466119 |    252.302681 | Sergio A. Muñoz-Gómez                                                                                                                                              |
| 242 |    228.663162 |    748.453232 | Matt Crook                                                                                                                                                         |
| 243 |    110.391552 |    745.906054 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 244 |    424.409821 |    752.543223 | Zimices                                                                                                                                                            |
| 245 |    688.804778 |    451.768502 | Matt Crook                                                                                                                                                         |
| 246 |    995.496834 |    132.991373 | Kanako Bessho-Uehara                                                                                                                                               |
| 247 |    648.302179 |    463.592852 | Collin Gross                                                                                                                                                       |
| 248 |    310.459984 |    281.829686 | Matt Crook                                                                                                                                                         |
| 249 |    273.183708 |    674.205257 | Joanna Wolfe                                                                                                                                                       |
| 250 |    443.320356 |    219.401564 | Christoph Schomburg                                                                                                                                                |
| 251 |    696.386805 |    784.718153 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                      |
| 252 |    685.142997 |    198.237508 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 253 |    713.145675 |    621.726502 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                    |
| 254 |    626.170274 |     77.588341 | Gareth Monger                                                                                                                                                      |
| 255 |    855.805168 |    310.375779 | Matt Crook                                                                                                                                                         |
| 256 |    250.906435 |    190.085010 | T. Michael Keesey (after Masteraah)                                                                                                                                |
| 257 |    979.664317 |    163.627751 | Gareth Monger                                                                                                                                                      |
| 258 |    994.275237 |    264.726971 | Ferran Sayol                                                                                                                                                       |
| 259 |    863.673928 |     97.698362 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 260 |    761.933344 |    531.908198 | (unknown)                                                                                                                                                          |
| 261 |    481.346198 |    136.662713 | Sarah Werning                                                                                                                                                      |
| 262 |    573.094677 |    254.702844 | C. Camilo Julián-Caballero                                                                                                                                         |
| 263 |   1009.438722 |    172.914351 | NA                                                                                                                                                                 |
| 264 |    935.373128 |    516.966958 | Markus A. Grohme                                                                                                                                                   |
| 265 |    997.766435 |    560.075664 | Jaime Headden                                                                                                                                                      |
| 266 |    833.492810 |    326.261931 | Scott Hartman                                                                                                                                                      |
| 267 |    924.961945 |     95.238139 | Dean Schnabel                                                                                                                                                      |
| 268 |    121.900459 |    245.429380 | Scott Hartman                                                                                                                                                      |
| 269 |     83.073443 |    153.286525 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 270 |    939.689276 |     13.240450 | Birgit Lang                                                                                                                                                        |
| 271 |    936.529560 |    323.072927 | Tasman Dixon                                                                                                                                                       |
| 272 |    264.226287 |    328.736259 | Jaime Headden                                                                                                                                                      |
| 273 |    167.607529 |    108.299163 | Sarah Werning                                                                                                                                                      |
| 274 |    315.387507 |    116.987150 | Tasman Dixon                                                                                                                                                       |
| 275 |    341.658687 |    434.497933 | Tasman Dixon                                                                                                                                                       |
| 276 |    414.363500 |    209.176192 | Michael Scroggie                                                                                                                                                   |
| 277 |    577.465383 |    547.059285 | NA                                                                                                                                                                 |
| 278 |     85.107754 |    724.388158 | Ferran Sayol                                                                                                                                                       |
| 279 |    140.351230 |    282.789789 | Rebecca Groom                                                                                                                                                      |
| 280 |    361.990769 |     35.978451 | Taenadoman                                                                                                                                                         |
| 281 |    996.128772 |    308.311999 | Tracy A. Heath                                                                                                                                                     |
| 282 |    231.674207 |    274.092455 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 283 |    313.342614 |    380.900003 | Rebecca Groom                                                                                                                                                      |
| 284 |     12.466636 |    224.306707 | Felix Vaux                                                                                                                                                         |
| 285 |    194.043720 |    791.884914 | Alex Slavenko                                                                                                                                                      |
| 286 |    152.611841 |    532.183812 | Margot Michaud                                                                                                                                                     |
| 287 |    275.739668 |    513.617408 | Steven Haddock • Jellywatch.org                                                                                                                                    |
| 288 |    340.398670 |     54.679207 | Gareth Monger                                                                                                                                                      |
| 289 |    946.329744 |    247.728475 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 290 |    820.143874 |    679.684350 | Roderic Page and Lois Page                                                                                                                                         |
| 291 |    724.745291 |    723.872234 | Markus A. Grohme                                                                                                                                                   |
| 292 |     25.507920 |    509.622383 | Noah Schlottman, photo by Carol Cummings                                                                                                                           |
| 293 |    631.244602 |    761.251760 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                          |
| 294 |    601.702845 |    120.586354 | Markus A. Grohme                                                                                                                                                   |
| 295 |    415.753422 |    663.904242 | Mali’o Kodis, photograph by Cordell Expeditions at Cal Academy                                                                                                     |
| 296 |    983.386880 |     20.161061 | Steven Traver                                                                                                                                                      |
| 297 |    315.580634 |    607.194722 | Matt Crook                                                                                                                                                         |
| 298 |    668.648558 |    169.804804 | Jagged Fang Designs                                                                                                                                                |
| 299 |    949.407905 |    680.693566 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 300 |    903.038358 |    250.354894 | Dianne Bray / Museum Victoria (vectorized by T. Michael Keesey)                                                                                                    |
| 301 |    446.455002 |    191.767546 | Julio Garza                                                                                                                                                        |
| 302 |    691.493078 |    426.434209 | FunkMonk                                                                                                                                                           |
| 303 |    860.739088 |     25.403556 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 304 |    653.918033 |    223.012025 | Zimices                                                                                                                                                            |
| 305 |     81.138039 |    581.215138 | CNZdenek                                                                                                                                                           |
| 306 |    835.532221 |    304.595529 | Gareth Monger                                                                                                                                                      |
| 307 |    586.339795 |    187.639852 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 308 |    704.508967 |    677.813198 | FJDegrange                                                                                                                                                         |
| 309 |    831.115596 |    577.483218 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                  |
| 310 |    851.711640 |    401.190413 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                                  |
| 311 |    388.722407 |     82.753983 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 312 |    741.352169 |     76.513138 | Roberto Díaz Sibaja                                                                                                                                                |
| 313 |    536.427454 |    726.547793 | Matt Crook                                                                                                                                                         |
| 314 |    586.709555 |    231.953710 | Matt Crook                                                                                                                                                         |
| 315 |    147.957320 |    322.053007 | Jagged Fang Designs                                                                                                                                                |
| 316 |    361.923339 |    290.049774 | Trond R. Oskars                                                                                                                                                    |
| 317 |    297.942967 |    264.289402 | Birgit Lang                                                                                                                                                        |
| 318 |    294.172269 |    152.675207 | Michelle Site                                                                                                                                                      |
| 319 |    962.580222 |    472.471331 | Cathy                                                                                                                                                              |
| 320 |    386.797380 |    663.802542 | George Edward Lodge                                                                                                                                                |
| 321 |    408.985913 |    386.150350 | Cathy                                                                                                                                                              |
| 322 |    584.054275 |    136.407532 | Scott Hartman                                                                                                                                                      |
| 323 |    357.090088 |     18.380144 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                       |
| 324 |    471.785863 |    741.646495 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                             |
| 325 |   1005.501282 |    609.864957 | Steven Traver                                                                                                                                                      |
| 326 |    842.211302 |    284.932047 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                             |
| 327 |    876.349547 |     54.387815 | Gopal Murali                                                                                                                                                       |
| 328 |    883.331155 |    228.213333 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                              |
| 329 |    203.060337 |    652.470275 | Rebecca Groom                                                                                                                                                      |
| 330 |    549.825513 |    112.037671 | NA                                                                                                                                                                 |
| 331 |     38.752662 |    516.216363 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 332 |    903.105627 |    364.289267 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                    |
| 333 |     47.062635 |    314.302785 | NA                                                                                                                                                                 |
| 334 |    323.618002 |    422.098461 | Dexter R. Mardis                                                                                                                                                   |
| 335 |    559.345951 |    641.105541 | Mariana Ruiz Villarreal (modified by T. Michael Keesey)                                                                                                            |
| 336 |    993.251161 |    436.638743 | Robert Gay                                                                                                                                                         |
| 337 |     45.202659 |    411.306041 | Tyler McCraney                                                                                                                                                     |
| 338 |    196.864007 |     73.043721 | Beth Reinke                                                                                                                                                        |
| 339 |    525.456195 |    426.873309 | Luis Cunha                                                                                                                                                         |
| 340 |    992.663085 |    348.026387 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                            |
| 341 |    548.605150 |     13.762769 | Jagged Fang Designs                                                                                                                                                |
| 342 |    972.070789 |    776.788572 | NA                                                                                                                                                                 |
| 343 |    800.022246 |     92.171105 | Margot Michaud                                                                                                                                                     |
| 344 |     48.510173 |    238.810972 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                               |
| 345 |     16.470936 |    616.096503 | Margot Michaud                                                                                                                                                     |
| 346 |    743.632007 |    511.296491 | Dr. Thomas G. Barnes, USFWS                                                                                                                                        |
| 347 |    616.540775 |    779.099553 | Steven Traver                                                                                                                                                      |
| 348 |     76.883533 |    442.960153 | Gareth Monger                                                                                                                                                      |
| 349 |    158.785534 |     66.698563 | Mason McNair                                                                                                                                                       |
| 350 |    929.901183 |    792.018758 | Felix Vaux                                                                                                                                                         |
| 351 |    686.186275 |    545.603600 | Matt Crook                                                                                                                                                         |
| 352 |    818.697424 |    223.607980 | Filip em                                                                                                                                                           |
| 353 |    126.065141 |    454.524296 | C. Camilo Julián-Caballero                                                                                                                                         |
| 354 |    535.564364 |    653.593629 | Allison Pease                                                                                                                                                      |
| 355 |    776.072760 |    448.784649 | NA                                                                                                                                                                 |
| 356 |    383.259915 |    633.190552 | Martien Brand (original photo), Renato Santos (vector silhouette)                                                                                                  |
| 357 |    241.843990 |    793.451751 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                     |
| 358 |    987.255128 |     57.981540 | Melissa Broussard                                                                                                                                                  |
| 359 |    707.358601 |     87.327177 | T. Michael Keesey (after Mauricio Antón)                                                                                                                           |
| 360 |    473.657329 |    486.619981 | Collin Gross                                                                                                                                                       |
| 361 |    994.853285 |    337.111340 | Lisa Byrne                                                                                                                                                         |
| 362 |    890.855098 |    531.230412 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                      |
| 363 |    634.190244 |    597.046089 | Chris huh                                                                                                                                                          |
| 364 |    322.306106 |    359.829084 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 365 |    995.026392 |    792.147910 | Chris huh                                                                                                                                                          |
| 366 |    480.513530 |    203.974083 | T. Michael Keesey                                                                                                                                                  |
| 367 |    401.934832 |    261.527388 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 368 |    888.182976 |    634.195256 | NA                                                                                                                                                                 |
| 369 |    616.632434 |     56.936692 | Yan Wong                                                                                                                                                           |
| 370 |    269.293132 |      9.205887 | Tasman Dixon                                                                                                                                                       |
| 371 |    183.867255 |    765.695182 | Matt Crook                                                                                                                                                         |
| 372 |    516.262311 |    603.442481 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                                     |
| 373 |    632.375915 |    202.258997 | Matus Valach                                                                                                                                                       |
| 374 |    892.779001 |    727.791940 | Gabriela Palomo-Munoz                                                                                                                                              |
| 375 |    847.612487 |    585.302798 | Matt Crook                                                                                                                                                         |
| 376 |    641.973531 |    612.429783 | Scott Hartman                                                                                                                                                      |
| 377 |   1000.613998 |    736.593918 | Matt Crook                                                                                                                                                         |
| 378 |    346.113653 |     44.815999 | Dean Schnabel                                                                                                                                                      |
| 379 |    821.408442 |     60.821992 | Joanna Wolfe                                                                                                                                                       |
| 380 |    163.817301 |    783.245906 | James Neenan                                                                                                                                                       |
| 381 |    218.784694 |    254.698756 | Ingo Braasch                                                                                                                                                       |
| 382 |     94.645139 |    114.297261 | Scott Hartman                                                                                                                                                      |
| 383 |    347.449948 |      7.106433 | Scott Hartman                                                                                                                                                      |
| 384 |    629.365980 |      5.825481 | Chris huh                                                                                                                                                          |
| 385 |    311.693759 |    441.893169 | Remes K, Ortega F, Fierro I, Joger U, Kosma R, et al.                                                                                                              |
| 386 |    971.894266 |    110.354182 | Felix Vaux                                                                                                                                                         |
| 387 |    137.965985 |    270.202896 | Margot Michaud                                                                                                                                                     |
| 388 |    129.627880 |    117.375678 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 389 |    966.461157 |    519.599611 | Lisa Byrne                                                                                                                                                         |
| 390 |    466.614053 |    241.370462 | Luis Cunha                                                                                                                                                         |
| 391 |    110.358048 |    624.207473 | Chris huh                                                                                                                                                          |
| 392 |    267.790875 |    751.788850 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                              |
| 393 |    672.730339 |     38.566151 | Beth Reinke                                                                                                                                                        |
| 394 |    138.447166 |    477.022631 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                      |
| 395 |    374.044631 |    499.133697 | Jose Carlos Arenas-Monroy                                                                                                                                          |
| 396 |    856.519734 |    364.061915 | Scott Hartman                                                                                                                                                      |
| 397 |    488.498866 |    577.978320 | Tasman Dixon                                                                                                                                                       |
| 398 |    512.377662 |    148.320243 | Gareth Monger                                                                                                                                                      |
| 399 |    291.736881 |     62.327859 | Zimices                                                                                                                                                            |
| 400 |     16.224356 |    255.203580 | Ferran Sayol                                                                                                                                                       |
| 401 |    509.309157 |    720.425813 | Pete Buchholz                                                                                                                                                      |
| 402 |    845.919707 |    381.470504 | Chris huh                                                                                                                                                          |
| 403 |    178.128671 |    321.127743 | T. Michael Keesey                                                                                                                                                  |
| 404 |    876.156689 |    408.360131 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                  |
| 405 |    161.504808 |    376.435475 | Steven Traver                                                                                                                                                      |
| 406 |    237.883888 |    260.099868 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                        |
| 407 |    294.274168 |    208.777049 | Zimices                                                                                                                                                            |
| 408 |    543.168228 |    779.927208 | Brian Swartz (vectorized by T. Michael Keesey)                                                                                                                     |
| 409 |    745.704339 |    347.383115 | Matt Crook                                                                                                                                                         |
| 410 |    841.193862 |    210.852865 | Chris huh                                                                                                                                                          |
| 411 |    561.660381 |    679.266542 | Sarah Werning                                                                                                                                                      |
| 412 |    613.321820 |    363.055048 | Matt Crook                                                                                                                                                         |
| 413 |    511.666417 |    187.787120 | Matt Crook                                                                                                                                                         |
| 414 |    453.682016 |     81.111254 | Jaime Headden                                                                                                                                                      |
| 415 |    471.453035 |    791.767226 | Chris huh                                                                                                                                                          |
| 416 |   1006.861770 |    572.473741 | Ferran Sayol                                                                                                                                                       |
| 417 |    995.284723 |    515.151932 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 418 |    151.772800 |    617.692244 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                 |
| 419 |    338.295301 |    754.549159 | T. Michael Keesey (after Heinrich Harder)                                                                                                                          |
| 420 |    963.782941 |    185.011462 | Zimices                                                                                                                                                            |
| 421 |    120.992214 |    554.742003 | Markus A. Grohme                                                                                                                                                   |
| 422 |     27.621271 |    357.554302 | Jagged Fang Designs                                                                                                                                                |
| 423 |    739.025544 |    206.047596 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                                   |
| 424 |    802.690268 |    618.155923 | NA                                                                                                                                                                 |
| 425 |    431.032737 |    259.151047 | NA                                                                                                                                                                 |
| 426 |    344.557768 |    186.274083 | Zimices                                                                                                                                                            |
| 427 |    546.816601 |    390.703218 | Beth Reinke                                                                                                                                                        |
| 428 |    691.634827 |    403.945657 | Andreas Hejnol                                                                                                                                                     |
| 429 |    666.878984 |    398.464670 | Chris huh                                                                                                                                                          |
| 430 |   1006.065788 |    645.822183 | Ferran Sayol                                                                                                                                                       |
| 431 |    255.923104 |    430.164803 | Caleb M. Brown                                                                                                                                                     |
| 432 |    756.531012 |    257.632429 | NA                                                                                                                                                                 |
| 433 |    624.029931 |    673.138756 | Birgit Lang                                                                                                                                                        |
| 434 |    561.759247 |    700.971212 | Smokeybjb                                                                                                                                                          |
| 435 |    215.385846 |    704.768110 | Margot Michaud                                                                                                                                                     |
| 436 |    929.220556 |    376.035390 | Gareth Monger                                                                                                                                                      |
| 437 |    740.854942 |    559.111060 | Peileppe                                                                                                                                                           |
| 438 |    293.669942 |    725.717361 | Rene Martin                                                                                                                                                        |
| 439 |    121.385758 |    207.754929 | M Kolmann                                                                                                                                                          |
| 440 |    597.526084 |    462.228384 | Kamil S. Jaron                                                                                                                                                     |
| 441 |    837.419530 |    341.566960 | Gareth Monger                                                                                                                                                      |
| 442 |    957.467984 |    256.312378 | Tasman Dixon                                                                                                                                                       |
| 443 |    901.442689 |    112.413620 | Melissa Broussard                                                                                                                                                  |
| 444 |    216.374532 |    516.780082 | Matt Crook                                                                                                                                                         |
| 445 |    707.683152 |    654.595730 | Margot Michaud                                                                                                                                                     |
| 446 |    149.329517 |    660.577882 | Steven Traver                                                                                                                                                      |
| 447 |    513.308685 |    749.418817 | C. Camilo Julián-Caballero                                                                                                                                         |
| 448 |    447.548398 |     94.975800 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                          |
| 449 |     13.276316 |    173.124205 | Gareth Monger                                                                                                                                                      |
| 450 |    370.575546 |    389.854119 | Mathilde Cordellier                                                                                                                                                |
| 451 |     96.906295 |    653.400796 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                    |
| 452 |     16.524799 |    694.760186 | Margot Michaud                                                                                                                                                     |
| 453 |    616.177392 |    657.480654 | Maxime Dahirel                                                                                                                                                     |
| 454 |    636.804015 |     46.244253 | Noah Schlottman, photo by Casey Dunn                                                                                                                               |
| 455 |    274.354679 |    691.716181 | Chase Brownstein                                                                                                                                                   |
| 456 |    455.798336 |    599.073761 | Dmitry Bogdanov                                                                                                                                                    |
| 457 |    400.984276 |    603.376400 | Tasman Dixon                                                                                                                                                       |
| 458 |    758.956710 |    123.076609 | T. Michael Keesey                                                                                                                                                  |
| 459 |    343.641382 |    712.599051 | Jennifer Trimble                                                                                                                                                   |
| 460 |    652.921859 |    671.812598 | Arthur S. Brum                                                                                                                                                     |
| 461 |    587.647916 |    400.796598 | Gareth Monger                                                                                                                                                      |
| 462 |    561.824446 |    143.928807 | Zimices                                                                                                                                                            |
| 463 |     61.039665 |    137.347345 | Zimices                                                                                                                                                            |
| 464 |    349.917513 |    788.496722 | Gareth Monger                                                                                                                                                      |
| 465 |     19.194835 |    607.077691 | T. Michael Keesey                                                                                                                                                  |
| 466 |    288.272407 |    428.262228 | Yan Wong                                                                                                                                                           |
| 467 |    642.742502 |    264.391505 | Ignacio Contreras                                                                                                                                                  |
| 468 |   1004.943659 |    219.657013 | Christoph Schomburg                                                                                                                                                |
| 469 |    569.076113 |    704.239985 | Tasman Dixon                                                                                                                                                       |
| 470 |   1005.122786 |    709.662765 | S.Martini                                                                                                                                                          |
| 471 |     25.739293 |    380.892178 | Maija Karala                                                                                                                                                       |
| 472 |    849.801881 |    445.825272 | Tony Ayling                                                                                                                                                        |
| 473 |    496.985043 |    701.882169 | Benjamin Monod-Broca                                                                                                                                               |
| 474 |   1005.931229 |    768.026476 | Davidson Sodré                                                                                                                                                     |
| 475 |    935.535874 |    223.958759 | Matt Crook                                                                                                                                                         |
| 476 |    995.200328 |    212.103967 | Smokeybjb                                                                                                                                                          |
| 477 |    286.413929 |    138.252481 | NA                                                                                                                                                                 |
| 478 |    587.740606 |     82.583387 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 479 |    687.073123 |    723.860623 | Christian A. Masnaghetti                                                                                                                                           |
| 480 |    338.869856 |    504.442141 | Maija Karala                                                                                                                                                       |
| 481 |    189.391665 |    623.986712 | Margot Michaud                                                                                                                                                     |
| 482 |    786.733512 |      6.737094 | Tasman Dixon                                                                                                                                                       |
| 483 |      7.964501 |    666.604454 | Ferran Sayol                                                                                                                                                       |
| 484 |   1019.163179 |    543.420440 | Gareth Monger                                                                                                                                                      |
| 485 |    285.956516 |    327.400946 | T. Michael Keesey                                                                                                                                                  |
| 486 |    874.390174 |    433.464933 | Alexander Schmidt-Lebuhn                                                                                                                                           |
| 487 |    850.129484 |    113.898411 | Todd Marshall, vectorized by Zimices                                                                                                                               |
| 488 |     73.851793 |    616.975130 | Alex Slavenko                                                                                                                                                      |
| 489 |    679.705617 |    793.313436 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                   |
| 490 |    712.442619 |    331.179846 | Jagged Fang Designs                                                                                                                                                |
| 491 |    467.006359 |    412.276403 | Matt Martyniuk                                                                                                                                                     |
| 492 |    727.095683 |    717.006377 | Chris huh                                                                                                                                                          |
| 493 |    142.413612 |    235.233740 | Kai R. Caspar                                                                                                                                                      |
| 494 |    310.885147 |    625.101501 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                              |
| 495 |    158.785883 |    521.743813 | Jagged Fang Designs                                                                                                                                                |
| 496 |    557.586280 |    716.172512 | Dean Schnabel                                                                                                                                                      |
| 497 |    242.443205 |    670.417893 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                       |
| 498 |     83.988275 |    666.045516 | Zimices                                                                                                                                                            |
| 499 |    366.186109 |    156.353563 | Gareth Monger                                                                                                                                                      |
| 500 |    955.411162 |    241.904610 | FunkMonk                                                                                                                                                           |
| 501 |    663.752493 |    209.664682 | Jaime Headden                                                                                                                                                      |
| 502 |    811.983829 |    288.690941 | Christine Axon                                                                                                                                                     |
| 503 |    656.887816 |      9.958009 | Chris huh                                                                                                                                                          |
| 504 |    409.557673 |    795.313007 | Iain Reid                                                                                                                                                          |
| 505 |      9.434428 |    143.498350 | Tyler Greenfield                                                                                                                                                   |
| 506 |     55.382807 |    793.505038 | Scott Hartman                                                                                                                                                      |
| 507 |    887.524001 |    218.130748 | Gareth Monger                                                                                                                                                      |
| 508 |    826.587199 |    142.975627 | Matt Crook                                                                                                                                                         |
| 509 |    135.097673 |    648.919552 | Cesar Julian                                                                                                                                                       |
| 510 |    174.175697 |    437.760602 | Mathew Wedel                                                                                                                                                       |
| 511 |    597.767810 |    498.877320 | Nobu Tamura                                                                                                                                                        |
| 512 |    289.325562 |    478.251077 | Katie S. Collins                                                                                                                                                   |
| 513 |    872.772271 |    663.343462 | Margot Michaud                                                                                                                                                     |
| 514 |   1000.675988 |    110.772596 | Tasman Dixon                                                                                                                                                       |
| 515 |     77.393940 |    311.115199 | Philip Chalmers (vectorized by T. Michael Keesey)                                                                                                                  |
| 516 |    475.441998 |     91.988840 | Gareth Monger                                                                                                                                                      |
| 517 |    426.884298 |      7.518519 | Jagged Fang Designs                                                                                                                                                |
| 518 |    856.391777 |    433.791274 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                      |
| 519 |    434.396795 |    292.285779 | Margot Michaud                                                                                                                                                     |
| 520 |    623.707666 |    557.302389 | Sarah Werning                                                                                                                                                      |
| 521 |    882.090956 |    171.616196 | Michele M Tobias                                                                                                                                                   |
| 522 |    829.933569 |    597.245241 | C. Camilo Julián-Caballero                                                                                                                                         |
| 523 |    198.980718 |    274.786806 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                   |
| 524 |    438.924083 |    612.744797 | Steven Blackwood                                                                                                                                                   |

    #> Your tweet has been posted!
