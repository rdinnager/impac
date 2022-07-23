
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

David Liao, L. Shyamal, Richard J. Harris, Zimices, M Kolmann, Julia B
McHugh, Matt Crook, Jose Carlos Arenas-Monroy, Gabriela Palomo-Munoz,
Armin Reindl, Ferran Sayol, Jagged Fang Designs, Dean Schnabel, Crystal
Maier, Anthony Caravaggi, Harold N Eyster, Benjamint444, Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
Haplochromis (vectorized by T. Michael Keesey), Ieuan Jones, Margot
Michaud, Maija Karala, Scott Hartman, Chuanixn Yu, Christoph Schomburg,
Nobu Tamura (vectorized by T. Michael Keesey), Nobu Tamura (modified by
T. Michael Keesey), Ramona J Heim, Steven Coombs, Caleb M. Brown, Julio
Garza, Duane Raver/USFWS, Andy Wilson, James R. Spotila and Ray
Chatterji, Michelle Site, Gareth Monger, Chris huh, Conty (vectorized by
T. Michael Keesey), T. Michael Keesey, Nobu Tamura, vectorized by
Zimices, Ignacio Contreras, Joanna Wolfe, Markus A. Grohme, Noah
Schlottman, photo by Casey Dunn, Alexandre Vong, Skye McDavid,
Ghedoghedo (vectorized by T. Michael Keesey), Steven Traver,
Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Tasman Dixon, Tracy A. Heath, Douglas
Brown (modified by T. Michael Keesey), Felix Vaux, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Erika Schumacher, S.Martini, Frank
Denota, Nicholas J. Czaplewski, vectorized by Zimices, Kailah Thorn &
Mark Hutchinson, Steven Haddock • Jellywatch.org, T. Michael Keesey
(after C. De Muizon), David Orr, Jaime Headden, Noah Schlottman, Dmitry
Bogdanov, Auckland Museum and T. Michael Keesey, Katie S. Collins,
Michael Scroggie, from original photograph by Gary M. Stolz, USFWS
(original photograph in public domain)., Tony Ayling (vectorized by
Milton Tan), Griensteidl and T. Michael Keesey, Sarah Werning, Rebecca
Groom, Lily Hughes, Karla Martinez, Ben Liebeskind, Fernando Carezzano,
Sam Fraser-Smith (vectorized by T. Michael Keesey), Zsoldos Márton
(vectorized by T. Michael Keesey), Hugo Gruson, Juan Carlos Jerí, Tauana
J. Cunha, FunkMonk, Mo Hassan, nicubunu, Chloé Schmidt, Rachel Shoop,
Falconaumanni and T. Michael Keesey, Robert Bruce Horsfall, vectorized
by Zimices, Tyler Greenfield, Jebulon (vectorized by T. Michael Keesey),
Beth Reinke, I. Sáček, Sr. (vectorized by T. Michael Keesey), Esme
Ashe-Jepson, Archaeodontosaurus (vectorized by T. Michael Keesey), Nobu
Tamura (vectorized by A. Verrière), Emma Hughes, Melissa Broussard, C.
Camilo Julián-Caballero, Gopal Murali, Wynston Cooper (photo) and
Albertonykus (silhouette), Emily Willoughby, Kamil S. Jaron, Aline M.
Ghilardi, Paul O. Lewis, Carlos Cano-Barbacil, Ludwik Gąsiorowski,
Mattia Menchetti, Evan-Amos (vectorized by T. Michael Keesey), Emily
Jane McTavish, Mathieu Basille, Mykle Hoban, Kai R. Caspar, Iain Reid,
Birgit Lang, Smokeybjb, Jessica Anne Miller, Robbie N. Cada (modified by
T. Michael Keesey), Charles R. Knight (vectorized by T. Michael Keesey),
Ricardo Araújo, terngirl, (unknown), Ellen Edmonson (illustration) and
Timothy J. Bartley (silhouette), Jake Warner, Matt Martyniuk (vectorized
by T. Michael Keesey), Tod Robbins, Alexander Schmidt-Lebuhn, Maxime
Dahirel, Sergio A. Muñoz-Gómez, Frederick William Frohawk (vectorized by
T. Michael Keesey), Hans Hillewaert (vectorized by T. Michael Keesey),
Lisa Byrne, Roberto Díaz Sibaja, Yan Wong from drawing in The Century
Dictionary (1911), Collin Gross, Noah Schlottman, photo by Adam G.
Clause, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Original drawing by Antonov,
vectorized by Roberto Díaz Sibaja, Martin R. Smith, Smokeybjb
(vectorized by T. Michael Keesey), FJDegrange, New York Zoological
Society, Anna Willoughby, Rene Martin, Scott Hartman (modified by T.
Michael Keesey), T. Michael Keesey (from a photo by Maximilian Paradiz),
John Conway, Kanchi Nanjo, Blair Perry, SecretJellyMan - from Mason
McNair, Ghedo and T. Michael Keesey, Charles R. Knight, vectorized by
Zimices, Yan Wong, Arthur S. Brum, Tommaso Cancellario, Hans Hillewaert
(photo) and T. Michael Keesey (vectorization), Jessica Rick, Lisa M.
“Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Michael Scroggie, Scarlet23 (vectorized by T. Michael
Keesey), Scott Reid, T. K. Robinson, Jiekun He, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Luc Viatour (source photo) and Andreas Plank, Yan Wong
from illustration by Jules Richard (1907), Javier Luque, Christine Axon,
Ricardo N. Martinez & Oscar A. Alcober, CNZdenek, T. Tischler, Cesar
Julian, Becky Barnes, FunkMonk (Michael B.H.; vectorized by T. Michael
Keesey), Geoff Shaw, Melissa Ingala, Chris Jennings (Risiatto),
Smokeybjb (modified by Mike Keesey), Diego Fontaneto, Elisabeth A.
Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia
Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey),
Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja,
Alexandra van der Geer, Francesco “Architetto” Rollandin, Servien
(vectorized by T. Michael Keesey), Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, H. Filhol (vectorized by T. Michael
Keesey), Filip em, Mathew Wedel, Kenneth Lacovara (vectorized by T.
Michael Keesey), Gustav Mützel, Pete Buchholz, Zachary Quigley,
Terpsichores, Alex Slavenko, Tim Bertelink (modified by T. Michael
Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |     343.38599 |    640.655274 | NA                                                                                                                                                                    |
|   2 |     798.49952 |    254.003914 | David Liao                                                                                                                                                            |
|   3 |     959.33185 |    279.452749 | L. Shyamal                                                                                                                                                            |
|   4 |     287.80589 |    745.255596 | Richard J. Harris                                                                                                                                                     |
|   5 |     865.61359 |    626.158856 | Zimices                                                                                                                                                               |
|   6 |     317.51332 |    314.882863 | Zimices                                                                                                                                                               |
|   7 |     846.40785 |    446.437117 | M Kolmann                                                                                                                                                             |
|   8 |      78.19538 |    695.823106 | L. Shyamal                                                                                                                                                            |
|   9 |     700.34297 |    635.812702 | Julia B McHugh                                                                                                                                                        |
|  10 |     333.83444 |    149.937273 | Matt Crook                                                                                                                                                            |
|  11 |     885.13630 |    677.094490 | Zimices                                                                                                                                                               |
|  12 |     110.40936 |    389.005738 | Matt Crook                                                                                                                                                            |
|  13 |     698.34368 |    194.842143 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  14 |     538.66371 |    702.254727 | Matt Crook                                                                                                                                                            |
|  15 |     145.20261 |    541.656799 | NA                                                                                                                                                                    |
|  16 |     421.68949 |    383.871952 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  17 |     838.31316 |     81.510670 | Armin Reindl                                                                                                                                                          |
|  18 |     156.21434 |    265.400613 | Ferran Sayol                                                                                                                                                          |
|  19 |     630.88969 |    644.976155 | Jagged Fang Designs                                                                                                                                                   |
|  20 |     694.79828 |     85.477376 | Matt Crook                                                                                                                                                            |
|  21 |     578.78328 |    355.588791 | Dean Schnabel                                                                                                                                                         |
|  22 |     233.31006 |    133.288160 | Crystal Maier                                                                                                                                                         |
|  23 |     544.84457 |    123.353433 | Anthony Caravaggi                                                                                                                                                     |
|  24 |     486.31723 |    265.588695 | Harold N Eyster                                                                                                                                                       |
|  25 |      50.05603 |    261.641759 | Benjamint444                                                                                                                                                          |
|  26 |     716.16904 |    448.563368 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
|  27 |     579.94155 |    539.366635 | Matt Crook                                                                                                                                                            |
|  28 |     433.02782 |    504.214198 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
|  29 |     132.67699 |    114.471716 | Ieuan Jones                                                                                                                                                           |
|  30 |     296.71135 |    540.527085 | Margot Michaud                                                                                                                                                        |
|  31 |     466.36219 |     81.688284 | Maija Karala                                                                                                                                                          |
|  32 |     692.61677 |    763.317956 | Scott Hartman                                                                                                                                                         |
|  33 |     888.03791 |    172.470314 | Chuanixn Yu                                                                                                                                                           |
|  34 |     149.75455 |    177.673006 | Christoph Schomburg                                                                                                                                                   |
|  35 |     941.34234 |     59.057502 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  36 |     956.74492 |    757.739645 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  37 |     170.52123 |    719.879161 | Ramona J Heim                                                                                                                                                         |
|  38 |     426.04782 |    205.408396 | Matt Crook                                                                                                                                                            |
|  39 |     787.01709 |    562.249979 | Steven Coombs                                                                                                                                                         |
|  40 |     236.36460 |    416.085810 | Caleb M. Brown                                                                                                                                                        |
|  41 |     581.98833 |    769.430328 | Julio Garza                                                                                                                                                           |
|  42 |     740.80501 |    694.002819 | Jagged Fang Designs                                                                                                                                                   |
|  43 |     613.35648 |     53.441868 | M Kolmann                                                                                                                                                             |
|  44 |     270.83073 |    377.145833 | Duane Raver/USFWS                                                                                                                                                     |
|  45 |     970.08427 |    118.299053 | Andy Wilson                                                                                                                                                           |
|  46 |     369.56904 |    758.484747 | James R. Spotila and Ray Chatterji                                                                                                                                    |
|  47 |     848.55078 |    329.561285 | Michelle Site                                                                                                                                                         |
|  48 |     398.22480 |    463.450623 | Gareth Monger                                                                                                                                                         |
|  49 |      77.51169 |     43.168921 | Chris huh                                                                                                                                                             |
|  50 |     825.56964 |    743.945390 | Zimices                                                                                                                                                               |
|  51 |     711.75752 |    369.979292 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
|  52 |     817.66799 |    591.606334 | Dean Schnabel                                                                                                                                                         |
|  53 |     486.70130 |    619.487483 | Ferran Sayol                                                                                                                                                          |
|  54 |     935.23053 |    504.408921 | T. Michael Keesey                                                                                                                                                     |
|  55 |     944.36577 |    632.221734 | Chris huh                                                                                                                                                             |
|  56 |     566.46188 |    432.626911 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
|  57 |     279.58025 |     32.044968 | Ignacio Contreras                                                                                                                                                     |
|  58 |     501.75133 |    215.289301 | Joanna Wolfe                                                                                                                                                          |
|  59 |     662.87405 |    313.569309 | Markus A. Grohme                                                                                                                                                      |
|  60 |     300.83915 |    271.227898 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  61 |      63.13349 |    337.854879 | Ignacio Contreras                                                                                                                                                     |
|  62 |     982.79139 |    423.307633 | NA                                                                                                                                                                    |
|  63 |     718.94213 |     30.803400 | Dean Schnabel                                                                                                                                                         |
|  64 |      69.93745 |    785.567879 | Scott Hartman                                                                                                                                                         |
|  65 |     276.38570 |    249.648261 | Scott Hartman                                                                                                                                                         |
|  66 |     259.12457 |    462.575304 | Alexandre Vong                                                                                                                                                        |
|  67 |     922.27029 |    543.913799 | Skye McDavid                                                                                                                                                          |
|  68 |     777.03828 |    524.261036 | Markus A. Grohme                                                                                                                                                      |
|  69 |     674.95519 |    284.801127 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
|  70 |     533.59118 |     22.427538 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  71 |      73.95777 |     81.235171 | Ignacio Contreras                                                                                                                                                     |
|  72 |     661.17464 |    592.830385 | Steven Traver                                                                                                                                                         |
|  73 |      70.55604 |    629.570996 | Gareth Monger                                                                                                                                                         |
|  74 |      32.94473 |    161.073208 | T. Michael Keesey                                                                                                                                                     |
|  75 |     474.84233 |    786.051779 | Gareth Monger                                                                                                                                                         |
|  76 |     651.90634 |    714.874810 | Armin Reindl                                                                                                                                                          |
|  77 |     950.41412 |    364.496397 | Jagged Fang Designs                                                                                                                                                   |
|  78 |      78.27693 |    759.390206 | Chris huh                                                                                                                                                             |
|  79 |     764.88432 |    426.858091 | Fir0002/Flagstaffotos (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
|  80 |     777.18617 |    640.713489 | Andy Wilson                                                                                                                                                           |
|  81 |      38.45745 |    512.948384 | Jose Carlos Arenas-Monroy                                                                                                                                             |
|  82 |     347.48644 |     71.600426 | Gareth Monger                                                                                                                                                         |
|  83 |     423.31243 |     18.419099 | Tasman Dixon                                                                                                                                                          |
|  84 |     393.39631 |    590.778268 | Tracy A. Heath                                                                                                                                                        |
|  85 |     739.99569 |    782.114109 | Douglas Brown (modified by T. Michael Keesey)                                                                                                                         |
|  86 |      35.92651 |    586.605675 | Julio Garza                                                                                                                                                           |
|  87 |     120.89382 |    319.926328 | Markus A. Grohme                                                                                                                                                      |
|  88 |     747.88058 |    659.937986 | Felix Vaux                                                                                                                                                            |
|  89 |     216.71325 |    623.832332 | Jagged Fang Designs                                                                                                                                                   |
|  90 |     592.35607 |    259.016127 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  91 |     374.02506 |    189.675159 | Jagged Fang Designs                                                                                                                                                   |
|  92 |     963.21855 |    475.315748 | Gareth Monger                                                                                                                                                         |
|  93 |     292.78015 |    117.665581 | Erika Schumacher                                                                                                                                                      |
|  94 |     781.43950 |     62.489897 | Matt Crook                                                                                                                                                            |
|  95 |     165.29740 |    424.847786 | S.Martini                                                                                                                                                             |
|  96 |     221.55382 |    334.703248 | Steven Traver                                                                                                                                                         |
|  97 |     890.06283 |    300.876072 | Scott Hartman                                                                                                                                                         |
|  98 |     360.32063 |    223.174570 | Ferran Sayol                                                                                                                                                          |
|  99 |      48.55652 |    731.373187 | Frank Denota                                                                                                                                                          |
| 100 |     972.16968 |    699.889817 | Ieuan Jones                                                                                                                                                           |
| 101 |     328.01412 |    493.460568 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 102 |     494.69624 |    770.834950 | Nicholas J. Czaplewski, vectorized by Zimices                                                                                                                         |
| 103 |     952.95636 |    334.374301 | Kailah Thorn & Mark Hutchinson                                                                                                                                        |
| 104 |     776.53934 |    490.867829 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 105 |     420.38815 |    556.058308 | Tracy A. Heath                                                                                                                                                        |
| 106 |     235.86980 |    200.428523 | Steven Haddock • Jellywatch.org                                                                                                                                       |
| 107 |     872.63677 |    250.539050 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 108 |     108.05401 |     64.801472 | Dean Schnabel                                                                                                                                                         |
| 109 |      93.60268 |     19.687388 | NA                                                                                                                                                                    |
| 110 |     939.94824 |    541.762425 | Ferran Sayol                                                                                                                                                          |
| 111 |     953.32578 |    584.860407 | Scott Hartman                                                                                                                                                         |
| 112 |      79.51451 |    455.207082 | David Orr                                                                                                                                                             |
| 113 |     459.02341 |    634.336684 | Zimices                                                                                                                                                               |
| 114 |     163.06122 |     76.127088 | Jaime Headden                                                                                                                                                         |
| 115 |     185.48429 |     49.677048 | Noah Schlottman                                                                                                                                                       |
| 116 |     777.75026 |    107.893684 | Dmitry Bogdanov                                                                                                                                                       |
| 117 |      56.35080 |    397.873591 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 118 |     250.57694 |    224.695751 | Markus A. Grohme                                                                                                                                                      |
| 119 |     221.72692 |    506.845814 | Katie S. Collins                                                                                                                                                      |
| 120 |     388.22780 |    153.969506 | Margot Michaud                                                                                                                                                        |
| 121 |     226.16862 |    537.763248 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 122 |     208.45479 |    294.632488 | Zimices                                                                                                                                                               |
| 123 |     692.05183 |    518.461163 | NA                                                                                                                                                                    |
| 124 |     377.22521 |     34.389663 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
| 125 |     681.49912 |    447.700598 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 126 |     248.53809 |    790.770894 | Sarah Werning                                                                                                                                                         |
| 127 |     985.29094 |    678.192572 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 128 |     820.54787 |    168.348075 | Rebecca Groom                                                                                                                                                         |
| 129 |     965.01167 |    552.141238 | Lily Hughes                                                                                                                                                           |
| 130 |     207.77123 |     10.906150 | Gareth Monger                                                                                                                                                         |
| 131 |     597.59608 |    617.600677 | T. Michael Keesey                                                                                                                                                     |
| 132 |     442.00275 |    755.162092 | Crystal Maier                                                                                                                                                         |
| 133 |     141.57920 |     65.216294 | Karla Martinez                                                                                                                                                        |
| 134 |     408.87611 |     48.999352 | Ben Liebeskind                                                                                                                                                        |
| 135 |     847.47444 |    231.200548 | NA                                                                                                                                                                    |
| 136 |      56.22803 |    550.794506 | Matt Crook                                                                                                                                                            |
| 137 |     593.31861 |    100.399749 | Michelle Site                                                                                                                                                         |
| 138 |     842.76517 |     11.715255 | Fernando Carezzano                                                                                                                                                    |
| 139 |     119.36501 |    655.771552 | Chris huh                                                                                                                                                             |
| 140 |     688.07847 |    110.837513 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 141 |     856.13378 |    152.847862 | Zsoldos Márton (vectorized by T. Michael Keesey)                                                                                                                      |
| 142 |     939.62750 |    395.423995 | T. Michael Keesey                                                                                                                                                     |
| 143 |     888.84801 |     73.844224 | Steven Traver                                                                                                                                                         |
| 144 |     236.72860 |    720.987520 | Hugo Gruson                                                                                                                                                           |
| 145 |     734.75520 |    289.994921 | Gareth Monger                                                                                                                                                         |
| 146 |     372.31100 |    422.018274 | Juan Carlos Jerí                                                                                                                                                      |
| 147 |     307.55247 |    135.813181 | Matt Crook                                                                                                                                                            |
| 148 |     930.82398 |    112.454954 | Matt Crook                                                                                                                                                            |
| 149 |     392.87910 |    252.081613 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 150 |     739.40614 |    738.369021 | T. Michael Keesey                                                                                                                                                     |
| 151 |     680.48998 |    699.108379 | Margot Michaud                                                                                                                                                        |
| 152 |     557.77607 |    275.118017 | Tauana J. Cunha                                                                                                                                                       |
| 153 |     445.19588 |    488.862051 | Margot Michaud                                                                                                                                                        |
| 154 |     646.52463 |    677.696682 | T. Michael Keesey                                                                                                                                                     |
| 155 |     691.52284 |    342.377953 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 156 |     274.70829 |    784.101671 | NA                                                                                                                                                                    |
| 157 |     641.23314 |    564.244350 | Chris huh                                                                                                                                                             |
| 158 |     896.51922 |    719.129006 | FunkMonk                                                                                                                                                              |
| 159 |     309.22293 |    222.341184 | Mo Hassan                                                                                                                                                             |
| 160 |     606.79484 |     19.327749 | Matt Crook                                                                                                                                                            |
| 161 |     680.54564 |    538.398216 | Christoph Schomburg                                                                                                                                                   |
| 162 |     279.07286 |    694.280747 | nicubunu                                                                                                                                                              |
| 163 |     992.13887 |    791.213253 | Chris huh                                                                                                                                                             |
| 164 |     545.15017 |    240.157099 | Chloé Schmidt                                                                                                                                                         |
| 165 |     488.60277 |    461.582336 | Matt Crook                                                                                                                                                            |
| 166 |     751.62754 |    382.828140 | Rachel Shoop                                                                                                                                                          |
| 167 |     622.73182 |    127.491033 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 168 |      50.54120 |    656.157187 | Scott Hartman                                                                                                                                                         |
| 169 |     976.94965 |    219.942761 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 170 |     212.58477 |    708.785104 | Tyler Greenfield                                                                                                                                                      |
| 171 |     510.84676 |    671.972946 | Zimices                                                                                                                                                               |
| 172 |     225.86845 |    484.659431 | Matt Crook                                                                                                                                                            |
| 173 |     311.32947 |    604.695515 | Maija Karala                                                                                                                                                          |
| 174 |     536.33836 |    410.789995 | Erika Schumacher                                                                                                                                                      |
| 175 |     646.71905 |    441.009575 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                             |
| 176 |     774.05122 |    779.490070 | Gareth Monger                                                                                                                                                         |
| 177 |     340.50160 |     73.025618 | Beth Reinke                                                                                                                                                           |
| 178 |    1007.28192 |    591.882509 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                                       |
| 179 |     218.77408 |    784.815788 | Esme Ashe-Jepson                                                                                                                                                      |
| 180 |     642.69761 |    365.038694 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                                  |
| 181 |     603.75466 |    154.244849 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                               |
| 182 |     144.54022 |    408.428732 | Emma Hughes                                                                                                                                                           |
| 183 |     353.89049 |    788.444119 | Melissa Broussard                                                                                                                                                     |
| 184 |     238.55330 |    669.453783 | NA                                                                                                                                                                    |
| 185 |     500.25858 |    148.889298 | NA                                                                                                                                                                    |
| 186 |     902.90655 |    773.723269 | Tracy A. Heath                                                                                                                                                        |
| 187 |     582.92974 |    220.187225 | Scott Hartman                                                                                                                                                         |
| 188 |     442.54244 |    693.315613 | C. Camilo Julián-Caballero                                                                                                                                            |
| 189 |     929.65079 |    304.396393 | Felix Vaux                                                                                                                                                            |
| 190 |     611.31223 |    338.122928 | Gopal Murali                                                                                                                                                          |
| 191 |    1006.96064 |     23.458240 | Ferran Sayol                                                                                                                                                          |
| 192 |      69.61128 |    610.279344 | Scott Hartman                                                                                                                                                         |
| 193 |     945.21152 |    598.106368 | FunkMonk                                                                                                                                                              |
| 194 |     138.49189 |    334.015827 | Matt Crook                                                                                                                                                            |
| 195 |     138.83620 |    678.969495 | Ferran Sayol                                                                                                                                                          |
| 196 |     881.91910 |    276.009228 | Erika Schumacher                                                                                                                                                      |
| 197 |     262.06328 |     64.385512 | Gareth Monger                                                                                                                                                         |
| 198 |     431.81963 |    141.797507 | Dmitry Bogdanov                                                                                                                                                       |
| 199 |      13.08030 |    210.652009 | Gareth Monger                                                                                                                                                         |
| 200 |     167.57367 |    647.731861 | Markus A. Grohme                                                                                                                                                      |
| 201 |     391.08074 |    306.915052 | Scott Hartman                                                                                                                                                         |
| 202 |     115.63813 |    713.114416 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 203 |     919.07098 |    445.585298 | Margot Michaud                                                                                                                                                        |
| 204 |     537.10625 |    640.022876 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 205 |     817.82810 |    791.390737 | NA                                                                                                                                                                    |
| 206 |     551.64408 |    782.854267 | Emily Willoughby                                                                                                                                                      |
| 207 |     640.22003 |     33.804074 | Chris huh                                                                                                                                                             |
| 208 |     393.82271 |    126.587810 | Kamil S. Jaron                                                                                                                                                        |
| 209 |     845.75305 |    143.447493 | Steven Traver                                                                                                                                                         |
| 210 |     882.99844 |    131.643125 | Kamil S. Jaron                                                                                                                                                        |
| 211 |      18.65835 |     20.340979 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 212 |     764.17725 |    698.988064 | Felix Vaux                                                                                                                                                            |
| 213 |     212.66811 |    445.146980 | Aline M. Ghilardi                                                                                                                                                     |
| 214 |     337.25430 |    433.889134 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 215 |     387.95649 |    690.496807 | Ferran Sayol                                                                                                                                                          |
| 216 |     982.00596 |    661.766923 | Ramona J Heim                                                                                                                                                         |
| 217 |     809.23778 |     17.491771 | Anthony Caravaggi                                                                                                                                                     |
| 218 |     565.45302 |    612.806927 | Ferran Sayol                                                                                                                                                          |
| 219 |     912.64938 |    192.345944 | Armin Reindl                                                                                                                                                          |
| 220 |     681.53129 |    407.624587 | Ignacio Contreras                                                                                                                                                     |
| 221 |     733.40237 |    328.166119 | Steven Traver                                                                                                                                                         |
| 222 |     279.17856 |    592.971578 | Steven Traver                                                                                                                                                         |
| 223 |     874.57123 |     18.407726 | Paul O. Lewis                                                                                                                                                         |
| 224 |     912.09845 |     11.979288 | Carlos Cano-Barbacil                                                                                                                                                  |
| 225 |     467.26128 |    735.119661 | Melissa Broussard                                                                                                                                                     |
| 226 |     406.32155 |    273.186428 | NA                                                                                                                                                                    |
| 227 |     478.24534 |    676.211776 | Gareth Monger                                                                                                                                                         |
| 228 |     362.14186 |    561.796078 | Ludwik Gąsiorowski                                                                                                                                                    |
| 229 |     453.40454 |    525.919127 | Dean Schnabel                                                                                                                                                         |
| 230 |      89.48081 |    520.270730 | Anthony Caravaggi                                                                                                                                                     |
| 231 |     626.43309 |    237.030439 | Mattia Menchetti                                                                                                                                                      |
| 232 |     590.81043 |    723.788074 | Markus A. Grohme                                                                                                                                                      |
| 233 |     228.27402 |    581.991650 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                           |
| 234 |      19.67159 |    242.738778 | Scott Hartman                                                                                                                                                         |
| 235 |     148.84760 |    219.582278 | Chris huh                                                                                                                                                             |
| 236 |     567.16742 |     62.224107 | Noah Schlottman                                                                                                                                                       |
| 237 |     747.48686 |    121.003381 | Chris huh                                                                                                                                                             |
| 238 |      15.16004 |    762.315826 | Erika Schumacher                                                                                                                                                      |
| 239 |     533.11732 |    334.335310 | Emily Willoughby                                                                                                                                                      |
| 240 |     947.29476 |    717.873585 | Erika Schumacher                                                                                                                                                      |
| 241 |     631.92637 |    789.376654 | Margot Michaud                                                                                                                                                        |
| 242 |     524.35859 |    467.814686 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 243 |      68.84781 |    368.382481 | Tasman Dixon                                                                                                                                                          |
| 244 |    1008.75477 |    461.044383 | Emily Jane McTavish                                                                                                                                                   |
| 245 |      26.64980 |    387.689170 | Mathieu Basille                                                                                                                                                       |
| 246 |     890.43134 |    104.170507 | Chuanixn Yu                                                                                                                                                           |
| 247 |     367.72073 |    279.822001 | Gareth Monger                                                                                                                                                         |
| 248 |     193.11222 |    437.691265 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
| 249 |    1007.14116 |    230.294814 | Gareth Monger                                                                                                                                                         |
| 250 |     765.47216 |    673.549100 | Margot Michaud                                                                                                                                                        |
| 251 |      64.08096 |    736.414859 | Mykle Hoban                                                                                                                                                           |
| 252 |     867.14454 |    700.728832 | Tasman Dixon                                                                                                                                                          |
| 253 |     957.97023 |      9.679398 | Kai R. Caspar                                                                                                                                                         |
| 254 |     669.90062 |    676.429157 | Iain Reid                                                                                                                                                             |
| 255 |     789.36880 |    321.477726 | Matt Crook                                                                                                                                                            |
| 256 |     372.36698 |    493.878079 | Birgit Lang                                                                                                                                                           |
| 257 |     885.88311 |    227.932013 | Andy Wilson                                                                                                                                                           |
| 258 |      71.45761 |     62.380799 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 259 |     544.12455 |    658.186884 | Matt Crook                                                                                                                                                            |
| 260 |     446.52405 |    606.857829 | Gareth Monger                                                                                                                                                         |
| 261 |     991.22713 |    780.598355 | Maija Karala                                                                                                                                                          |
| 262 |     641.30905 |     65.868324 | Smokeybjb                                                                                                                                                             |
| 263 |     748.06140 |    100.528247 | Margot Michaud                                                                                                                                                        |
| 264 |     652.11212 |    421.686030 | Tasman Dixon                                                                                                                                                          |
| 265 |     941.29410 |    679.784354 | Jessica Anne Miller                                                                                                                                                   |
| 266 |      89.00369 |    245.553879 | Felix Vaux                                                                                                                                                            |
| 267 |     525.03352 |    323.007258 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                                        |
| 268 |     695.93290 |     57.181438 | Charles R. Knight (vectorized by T. Michael Keesey)                                                                                                                   |
| 269 |     670.50152 |    558.437902 | Ricardo Araújo                                                                                                                                                        |
| 270 |     410.87085 |    531.571266 | C. Camilo Julián-Caballero                                                                                                                                            |
| 271 |     119.00326 |    775.001185 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 272 |     193.90467 |    367.671135 | terngirl                                                                                                                                                              |
| 273 |      80.53639 |    139.378941 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 274 |    1005.85119 |    616.501454 | Zimices                                                                                                                                                               |
| 275 |     208.89248 |    259.232881 | Ferran Sayol                                                                                                                                                          |
| 276 |     291.04698 |    251.510941 | (unknown)                                                                                                                                                             |
| 277 |     905.67735 |    205.475911 | NA                                                                                                                                                                    |
| 278 |     307.48894 |    703.154186 | Andy Wilson                                                                                                                                                           |
| 279 |     215.01185 |    758.164818 | Gareth Monger                                                                                                                                                         |
| 280 |     345.09688 |    473.214243 | Tasman Dixon                                                                                                                                                          |
| 281 |     592.38605 |     72.687039 | Margot Michaud                                                                                                                                                        |
| 282 |     784.98260 |    467.483539 | Ellen Edmonson (illustration) and Timothy J. Bartley (silhouette)                                                                                                     |
| 283 |     166.91109 |    306.728881 | Jake Warner                                                                                                                                                           |
| 284 |     471.38640 |    444.106178 | Markus A. Grohme                                                                                                                                                      |
| 285 |     239.25127 |    273.728024 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 286 |     764.27274 |      6.859679 | Steven Traver                                                                                                                                                         |
| 287 |      35.95723 |    367.581543 | Tod Robbins                                                                                                                                                           |
| 288 |     992.31133 |    442.738212 | Ben Liebeskind                                                                                                                                                        |
| 289 |     573.08733 |    191.540342 | Zimices                                                                                                                                                               |
| 290 |     685.53162 |    741.096536 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 291 |     553.11356 |    394.199351 | Maxime Dahirel                                                                                                                                                        |
| 292 |     125.74779 |    265.654636 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 293 |     422.37103 |     68.720292 | Auckland Museum and T. Michael Keesey                                                                                                                                 |
| 294 |     977.00726 |    186.108868 | Birgit Lang                                                                                                                                                           |
| 295 |     998.97663 |    566.819315 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 296 |     307.84244 |    397.808800 | Felix Vaux                                                                                                                                                            |
| 297 |     948.38746 |    419.846953 | Steven Traver                                                                                                                                                         |
| 298 |     418.06199 |    700.291269 | Chris huh                                                                                                                                                             |
| 299 |    1005.98044 |    252.105666 | Dean Schnabel                                                                                                                                                         |
| 300 |     227.70621 |    215.693716 | Markus A. Grohme                                                                                                                                                      |
| 301 |     125.12722 |    301.638870 | T. Michael Keesey                                                                                                                                                     |
| 302 |     764.67787 |    193.085361 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                           |
| 303 |     642.04288 |    340.162102 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 304 |     447.53399 |    718.328478 | Matt Crook                                                                                                                                                            |
| 305 |     525.01432 |    763.615704 | Lisa Byrne                                                                                                                                                            |
| 306 |     979.72122 |    605.542787 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 307 |     938.21870 |     23.048630 | Tauana J. Cunha                                                                                                                                                       |
| 308 |      49.28566 |    381.342347 | Zimices                                                                                                                                                               |
| 309 |     782.13336 |    368.695716 | Maija Karala                                                                                                                                                          |
| 310 |     773.45385 |    218.326719 | Gareth Monger                                                                                                                                                         |
| 311 |     248.08371 |    769.926763 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 312 |     796.66513 |    762.448378 | NA                                                                                                                                                                    |
| 313 |      91.09033 |    498.891110 | Roberto Díaz Sibaja                                                                                                                                                   |
| 314 |     860.75098 |    786.474555 | Ignacio Contreras                                                                                                                                                     |
| 315 |      16.34730 |    153.510209 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 316 |     422.51037 |    234.887610 | Ignacio Contreras                                                                                                                                                     |
| 317 |     203.00539 |    666.691633 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
| 318 |     711.30584 |    299.636103 | Collin Gross                                                                                                                                                          |
| 319 |     421.10510 |    436.140936 | Crystal Maier                                                                                                                                                         |
| 320 |     534.30209 |     49.438856 | Noah Schlottman, photo by Adam G. Clause                                                                                                                              |
| 321 |     582.95114 |     36.081322 | Zimices                                                                                                                                                               |
| 322 |     229.63805 |    554.615780 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 323 |      21.68992 |    663.643334 | NA                                                                                                                                                                    |
| 324 |     368.34000 |    531.294057 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                              |
| 325 |     329.26253 |    508.577452 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 326 |     541.49797 |    620.861598 | Margot Michaud                                                                                                                                                        |
| 327 |     556.49550 |    584.992632 | Steven Traver                                                                                                                                                         |
| 328 |     133.63934 |    435.101047 | Matt Crook                                                                                                                                                            |
| 329 |     364.91179 |    716.260988 | Andy Wilson                                                                                                                                                           |
| 330 |     316.33127 |    101.482263 | Gareth Monger                                                                                                                                                         |
| 331 |     705.45900 |    662.750800 | Original drawing by Antonov, vectorized by Roberto Díaz Sibaja                                                                                                        |
| 332 |     851.12897 |    279.436436 | Zimices                                                                                                                                                               |
| 333 |     490.95742 |    488.239511 | Dean Schnabel                                                                                                                                                         |
| 334 |     425.76669 |    178.550296 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 335 |     547.42256 |    313.983182 | T. Michael Keesey                                                                                                                                                     |
| 336 |      55.97505 |     21.288488 | Anthony Caravaggi                                                                                                                                                     |
| 337 |     743.44055 |    249.520208 | NA                                                                                                                                                                    |
| 338 |      21.97512 |    553.234925 | T. Michael Keesey                                                                                                                                                     |
| 339 |      95.87870 |    363.730900 | Markus A. Grohme                                                                                                                                                      |
| 340 |     247.16898 |    325.911434 | Andy Wilson                                                                                                                                                           |
| 341 |     347.38482 |    418.497720 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 342 |     811.38631 |    679.771182 | Margot Michaud                                                                                                                                                        |
| 343 |     594.86803 |    441.883373 | Martin R. Smith                                                                                                                                                       |
| 344 |     266.14120 |    397.119380 | Zimices                                                                                                                                                               |
| 345 |     243.34391 |    490.795342 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 346 |     524.74060 |    423.002417 | Zimices                                                                                                                                                               |
| 347 |     133.37918 |      7.831348 | Iain Reid                                                                                                                                                             |
| 348 |      33.00266 |    713.601228 | Emily Willoughby                                                                                                                                                      |
| 349 |     626.89864 |    252.851756 | NA                                                                                                                                                                    |
| 350 |      59.96229 |     10.120107 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 351 |     224.10666 |     54.568041 | Gareth Monger                                                                                                                                                         |
| 352 |     516.38635 |    186.556523 | Scott Hartman                                                                                                                                                         |
| 353 |     299.41612 |    481.593509 | Gareth Monger                                                                                                                                                         |
| 354 |     581.65750 |    574.659798 | Tasman Dixon                                                                                                                                                          |
| 355 |     720.88193 |    379.836186 | Matt Crook                                                                                                                                                            |
| 356 |    1006.49241 |    432.479471 | FJDegrange                                                                                                                                                            |
| 357 |     791.88019 |    612.786009 | T. Michael Keesey                                                                                                                                                     |
| 358 |     641.01241 |    738.872907 | FunkMonk                                                                                                                                                              |
| 359 |      96.03062 |    644.571964 | Matt Crook                                                                                                                                                            |
| 360 |     816.39000 |    774.543306 | New York Zoological Society                                                                                                                                           |
| 361 |     740.29635 |    357.620359 | Scott Hartman                                                                                                                                                         |
| 362 |     744.74420 |    599.558021 | Zimices                                                                                                                                                               |
| 363 |     570.91230 |    418.404071 | Anna Willoughby                                                                                                                                                       |
| 364 |     118.99161 |    468.486221 | Ferran Sayol                                                                                                                                                          |
| 365 |     362.64140 |    520.088118 | Rene Martin                                                                                                                                                           |
| 366 |     610.25005 |    693.475677 | Zimices                                                                                                                                                               |
| 367 |     382.92232 |    168.850165 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                         |
| 368 |     323.23070 |    706.540779 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 369 |     971.76668 |     78.239137 | T. Michael Keesey                                                                                                                                                     |
| 370 |     635.86292 |     76.390325 | Scott Hartman                                                                                                                                                         |
| 371 |    1010.21453 |    726.939734 | NA                                                                                                                                                                    |
| 372 |     911.35932 |    586.340125 | Margot Michaud                                                                                                                                                        |
| 373 |     593.33489 |    191.452640 | Benjamint444                                                                                                                                                          |
| 374 |     533.26967 |    747.293448 | Richard J. Harris                                                                                                                                                     |
| 375 |     279.20335 |    609.802405 | Scott Hartman                                                                                                                                                         |
| 376 |     240.58883 |    305.738752 | John Conway                                                                                                                                                           |
| 377 |     187.79476 |     82.975053 | Margot Michaud                                                                                                                                                        |
| 378 |     383.59165 |    200.176519 | Kanchi Nanjo                                                                                                                                                          |
| 379 |     880.66615 |    569.740102 | Blair Perry                                                                                                                                                           |
| 380 |     420.17805 |    315.212608 | Zimices                                                                                                                                                               |
| 381 |     463.64819 |     15.270850 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 382 |     917.77732 |    469.638764 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 383 |     413.46678 |    714.879451 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 384 |      40.86081 |    473.326449 | Armin Reindl                                                                                                                                                          |
| 385 |     210.99208 |    645.705739 | Yan Wong                                                                                                                                                              |
| 386 |    1006.00974 |    509.878577 | T. Michael Keesey                                                                                                                                                     |
| 387 |      28.26670 |    682.008585 | Sarah Werning                                                                                                                                                         |
| 388 |     870.45294 |    594.839788 | Arthur S. Brum                                                                                                                                                        |
| 389 |     974.41617 |     16.987054 | T. Michael Keesey (from a photo by Maximilian Paradiz)                                                                                                                |
| 390 |     252.82334 |    596.474108 | Tommaso Cancellario                                                                                                                                                   |
| 391 |     984.96333 |    724.422379 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                         |
| 392 |     767.31178 |    315.107194 | Christoph Schomburg                                                                                                                                                   |
| 393 |     671.60919 |    491.710514 | Matt Crook                                                                                                                                                            |
| 394 |     716.46205 |    112.393294 | Griensteidl and T. Michael Keesey                                                                                                                                     |
| 395 |     765.02173 |    322.644842 | Tasman Dixon                                                                                                                                                          |
| 396 |     870.94083 |    499.529358 | Gareth Monger                                                                                                                                                         |
| 397 |      15.11647 |    721.803358 | Markus A. Grohme                                                                                                                                                      |
| 398 |     312.98136 |      9.554107 | Steven Traver                                                                                                                                                         |
| 399 |     800.39790 |    491.519809 | Jagged Fang Designs                                                                                                                                                   |
| 400 |     401.17393 |    204.348974 | Andy Wilson                                                                                                                                                           |
| 401 |     507.11906 |     55.132339 | Jessica Rick                                                                                                                                                          |
| 402 |      76.07740 |    208.010060 | Zimices                                                                                                                                                               |
| 403 |     704.17584 |    239.973936 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
| 404 |     690.31928 |    729.644728 | Ignacio Contreras                                                                                                                                                     |
| 405 |      27.83233 |    404.836263 | Scott Hartman                                                                                                                                                         |
| 406 |     863.51164 |    524.521087 | Michael Scroggie                                                                                                                                                      |
| 407 |     107.52666 |    226.004418 | Margot Michaud                                                                                                                                                        |
| 408 |     324.93888 |    780.176142 | Scarlet23 (vectorized by T. Michael Keesey)                                                                                                                           |
| 409 |     699.17380 |    586.954838 | Margot Michaud                                                                                                                                                        |
| 410 |     154.26904 |     90.397225 | Scott Reid                                                                                                                                                            |
| 411 |     215.01629 |    394.468420 | T. K. Robinson                                                                                                                                                        |
| 412 |    1006.40455 |    203.049463 | Margot Michaud                                                                                                                                                        |
| 413 |     983.45870 |     32.072090 | Andy Wilson                                                                                                                                                           |
| 414 |     445.00756 |    660.605684 | Jagged Fang Designs                                                                                                                                                   |
| 415 |     153.86575 |    793.110923 | Tyler Greenfield                                                                                                                                                      |
| 416 |     631.96484 |     24.035198 | Jiekun He                                                                                                                                                             |
| 417 |     541.23797 |    452.761270 | Chris huh                                                                                                                                                             |
| 418 |      90.73185 |    541.088296 | Zimices                                                                                                                                                               |
| 419 |      51.88294 |    465.804274 | Tasman Dixon                                                                                                                                                          |
| 420 |     806.12402 |    146.323632 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 421 |     782.19648 |    459.654268 | Lisa Byrne                                                                                                                                                            |
| 422 |     670.07566 |    512.658326 | Luc Viatour (source photo) and Andreas Plank                                                                                                                          |
| 423 |      47.48903 |    107.275124 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 424 |     513.84981 |    448.069452 | (unknown)                                                                                                                                                             |
| 425 |     575.25827 |    502.603787 | Smokeybjb                                                                                                                                                             |
| 426 |    1003.80400 |    533.616263 | Scott Reid                                                                                                                                                            |
| 427 |     344.74951 |     45.094034 | Yan Wong from illustration by Jules Richard (1907)                                                                                                                    |
| 428 |     559.73590 |    493.400015 | Steven Traver                                                                                                                                                         |
| 429 |     143.50010 |    205.822791 | Javier Luque                                                                                                                                                          |
| 430 |     521.12177 |    546.166685 | Christine Axon                                                                                                                                                        |
| 431 |     812.34095 |    702.237603 | Steven Traver                                                                                                                                                         |
| 432 |      46.40965 |    482.822209 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 433 |     961.94778 |    729.909027 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 434 |    1008.87049 |    647.029321 | CNZdenek                                                                                                                                                              |
| 435 |     566.31976 |    376.698589 | Erika Schumacher                                                                                                                                                      |
| 436 |     615.46599 |     84.923076 | NA                                                                                                                                                                    |
| 437 |     657.35397 |    454.604965 | T. Tischler                                                                                                                                                           |
| 438 |     868.21996 |    342.772019 | Cesar Julian                                                                                                                                                          |
| 439 |     660.41838 |    266.881925 | Andy Wilson                                                                                                                                                           |
| 440 |     929.67085 |    130.104153 | Margot Michaud                                                                                                                                                        |
| 441 |     326.85206 |    210.769211 | Gareth Monger                                                                                                                                                         |
| 442 |      60.18969 |    454.980911 | Matt Crook                                                                                                                                                            |
| 443 |     152.76928 |     18.659158 | Becky Barnes                                                                                                                                                          |
| 444 |     681.12113 |    575.522014 | Dean Schnabel                                                                                                                                                         |
| 445 |     238.80512 |    694.564061 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                              |
| 446 |     284.11789 |    157.306023 | Caleb M. Brown                                                                                                                                                        |
| 447 |     292.17071 |    494.042656 | Scott Hartman                                                                                                                                                         |
| 448 |     906.16814 |    124.019682 | NA                                                                                                                                                                    |
| 449 |     493.30184 |    532.318591 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 450 |     163.79424 |    391.151062 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 451 |     985.53992 |    239.322108 | Emily Willoughby                                                                                                                                                      |
| 452 |     118.84102 |    287.157066 | Geoff Shaw                                                                                                                                                            |
| 453 |      85.36026 |    149.897274 | Melissa Ingala                                                                                                                                                        |
| 454 |     480.06039 |    552.389344 | Chris Jennings (Risiatto)                                                                                                                                             |
| 455 |     225.78904 |     73.488953 | Chris huh                                                                                                                                                             |
| 456 |     837.33790 |    299.192912 | Margot Michaud                                                                                                                                                        |
| 457 |     577.36579 |    646.460755 | Steven Traver                                                                                                                                                         |
| 458 |     957.89871 |    793.351948 | Smokeybjb                                                                                                                                                             |
| 459 |      17.79165 |    415.706587 | Jake Warner                                                                                                                                                           |
| 460 |     523.67475 |    312.075053 | Steven Coombs                                                                                                                                                         |
| 461 |      20.82034 |    742.012871 | Jagged Fang Designs                                                                                                                                                   |
| 462 |     774.85758 |    475.155649 | Sarah Werning                                                                                                                                                         |
| 463 |     513.21882 |    224.264936 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 464 |     672.80927 |    665.527496 | Chris huh                                                                                                                                                             |
| 465 |     896.27782 |    267.524149 | Scott Hartman                                                                                                                                                         |
| 466 |      92.01778 |    488.262501 | Smokeybjb (modified by Mike Keesey)                                                                                                                                   |
| 467 |     393.04073 |    328.897861 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 468 |     623.12985 |    667.329031 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 469 |     634.02943 |    702.089745 | Chloé Schmidt                                                                                                                                                         |
| 470 |      81.99168 |    184.729803 | Gareth Monger                                                                                                                                                         |
| 471 |     535.13233 |    498.712269 | Original drawing by Dmitry Bogdanov, vectorized by Roberto Díaz Sibaja                                                                                                |
| 472 |     525.32466 |    387.429267 | Matt Crook                                                                                                                                                            |
| 473 |     517.92973 |     74.350417 | Matt Crook                                                                                                                                                            |
| 474 |     953.12469 |    105.829561 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 475 |     551.00862 |    792.033398 | T. Michael Keesey                                                                                                                                                     |
| 476 |     470.23496 |    697.337321 | Alexandra van der Geer                                                                                                                                                |
| 477 |     441.20084 |    644.609509 | Scott Hartman                                                                                                                                                         |
| 478 |     895.72141 |    245.697625 | Scott Hartman                                                                                                                                                         |
| 479 |     424.96877 |    575.037054 | C. Camilo Julián-Caballero                                                                                                                                            |
| 480 |    1007.00743 |    686.606147 | Francesco “Architetto” Rollandin                                                                                                                                      |
| 481 |     466.80650 |    479.178296 | Servien (vectorized by T. Michael Keesey)                                                                                                                             |
| 482 |      40.92601 |    538.705170 | Scott Hartman                                                                                                                                                         |
| 483 |     460.36531 |    665.697549 | Martin R. Smith                                                                                                                                                       |
| 484 |    1013.42762 |    282.783795 | Anthony Caravaggi                                                                                                                                                     |
| 485 |     643.82542 |    404.611624 | Andy Wilson                                                                                                                                                           |
| 486 |     334.61195 |    454.394188 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                         |
| 487 |     479.51683 |    140.420620 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 488 |     334.25146 |    733.399432 | H. Filhol (vectorized by T. Michael Keesey)                                                                                                                           |
| 489 |     441.53851 |     18.490567 | Filip em                                                                                                                                                              |
| 490 |     192.97223 |    493.859154 | Ignacio Contreras                                                                                                                                                     |
| 491 |     454.28944 |    319.867707 | Mathew Wedel                                                                                                                                                          |
| 492 |    1002.45409 |    411.840035 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 493 |     353.17728 |    170.264838 | Michelle Site                                                                                                                                                         |
| 494 |     797.88609 |    475.121732 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 495 |     776.86508 |    746.832712 | Beth Reinke                                                                                                                                                           |
| 496 |      69.59550 |    596.994006 | Margot Michaud                                                                                                                                                        |
| 497 |     167.29820 |    133.103555 | Smokeybjb                                                                                                                                                             |
| 498 |     669.43475 |    791.251586 | Scott Hartman                                                                                                                                                         |
| 499 |    1012.48203 |    181.740259 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 500 |     904.16238 |    519.072179 | Gustav Mützel                                                                                                                                                         |
| 501 |     143.58509 |    645.955096 | Margot Michaud                                                                                                                                                        |
| 502 |     949.06473 |    210.813385 | Ferran Sayol                                                                                                                                                          |
| 503 |     289.41582 |    223.872965 | Yan Wong                                                                                                                                                              |
| 504 |      15.74839 |    472.075895 | Pete Buchholz                                                                                                                                                         |
| 505 |     612.98731 |    786.502624 | Markus A. Grohme                                                                                                                                                      |
| 506 |     431.44132 |    733.374961 | Ignacio Contreras                                                                                                                                                     |
| 507 |     603.44711 |    285.216556 | Zachary Quigley                                                                                                                                                       |
| 508 |     204.55743 |    475.659119 | Markus A. Grohme                                                                                                                                                      |
| 509 |      18.24230 |    355.722391 | Zimices                                                                                                                                                               |
| 510 |     124.45469 |     64.120412 | Yan Wong                                                                                                                                                              |
| 511 |     100.77789 |    616.185762 | Jagged Fang Designs                                                                                                                                                   |
| 512 |     473.21879 |    185.867426 | Terpsichores                                                                                                                                                          |
| 513 |     716.50169 |      7.045696 | Scott Hartman                                                                                                                                                         |
| 514 |     563.97455 |     97.967511 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 515 |    1005.85795 |    342.439888 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 516 |     869.55233 |    312.831879 | Steven Traver                                                                                                                                                         |
| 517 |     194.48460 |    780.446295 | Gopal Murali                                                                                                                                                          |
| 518 |     832.13353 |    661.795127 | Iain Reid                                                                                                                                                             |
| 519 |     555.89005 |     29.775000 | Sarah Werning                                                                                                                                                         |
| 520 |     194.13079 |    132.693125 | Ferran Sayol                                                                                                                                                          |
| 521 |     615.41814 |    627.843984 | M Kolmann                                                                                                                                                             |
| 522 |     795.79472 |    128.608379 | Michael Scroggie                                                                                                                                                      |
| 523 |     215.11402 |    600.903333 | Alex Slavenko                                                                                                                                                         |
| 524 |     607.48754 |    735.993341 | Tim Bertelink (modified by T. Michael Keesey)                                                                                                                         |
| 525 |     640.77497 |    619.526105 | Jagged Fang Designs                                                                                                                                                   |
| 526 |     560.17163 |     78.110163 | Matt Crook                                                                                                                                                            |
| 527 |     823.89702 |    483.627164 | Chris huh                                                                                                                                                             |
| 528 |     754.22239 |    722.967996 | Margot Michaud                                                                                                                                                        |
| 529 |     505.18308 |    509.431265 | Matt Crook                                                                                                                                                            |
| 530 |     319.86292 |    356.987829 | Michelle Site                                                                                                                                                         |
| 531 |     499.38971 |    755.956889 | Mykle Hoban                                                                                                                                                           |
| 532 |     271.25869 |    187.522718 | NA                                                                                                                                                                    |

    #> Your tweet has been posted!
