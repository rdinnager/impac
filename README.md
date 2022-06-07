
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

Matt Crook, C. Camilo Julián-Caballero, Gareth Monger, Xvazquez
(vectorized by William Gearty), T. Michael Keesey, Conty, Chris huh,
Scott Hartman, Lisa M. “Pixxl” (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Вальдимар (vectorized by T. Michael
Keesey), Florian Pfaff, Mali’o Kodis, image from Higgins and Kristensen,
1986, Mathew Callaghan, Zimices, Jimmy Bernot, (after Spotila 2004),
Smokeybjb, Campbell Fleming, Ron Holmes/U. S. Fish and Wildlife Service
(source photo), T. Michael Keesey (vectorization), FJDegrange, Daniel
Stadtmauer, Jagged Fang Designs, Chase Brownstein, Cesar Julian, L.
Shyamal, Kai R. Caspar, Steven Traver, Yan Wong (vectorization) from
1873 illustration, Gabriela Palomo-Munoz, Michele M Tobias, Anthony
Caravaggi, Emily Willoughby, Yan Wong from SEM by Arnau Sebé-Pedrós (PD
agreed by Iñaki Ruiz-Trillo), Andy Wilson, Darren Naish (vectorize by T.
Michael Keesey), Dmitry Bogdanov (vectorized by T. Michael Keesey),
Birgit Lang, Becky Barnes, Steven Coombs, Christine Axon, Michael P.
Taylor, Shyamal, Markus A. Grohme, Margot Michaud, Lip Kee Yap
(vectorized by T. Michael Keesey), Maija Karala, Nobu Tamura (vectorized
by T. Michael Keesey), Darren Naish (vectorized by T. Michael Keesey),
Raven Amos, Roberto Díaz Sibaja, Tasman Dixon, CNZdenek, Matt Martyniuk,
Carlos Cano-Barbacil, Mo Hassan, Scott Reid, Noah Schlottman, photo by
Casey Dunn, Terpsichores, Joanna Wolfe, Sarah Werning, B Kimmel, Yan
Wong from wikipedia drawing (PD: Pearson Scott Foresman), Chuanixn Yu,
Sam Fraser-Smith (vectorized by T. Michael Keesey), Ferran Sayol, Iain
Reid, Maxime Dahirel, Jan Sevcik (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, Dean Schnabel, Hugo Gruson, Jaime
Headden, Dmitry Bogdanov, Tauana J. Cunha, Rainer Schoch, Yan Wong,
Kanchi Nanjo, Obsidian Soul (vectorized by T. Michael Keesey),
Ghedoghedo (vectorized by T. Michael Keesey), Jan A. Venter, Herbert H.
T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B.
Chaves), E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized
by T. Michael Keesey), Mathew Wedel, Sergio A. Muñoz-Gómez, Lafage, Jose
Carlos Arenas-Monroy, Brad McFeeters (vectorized by T. Michael Keesey),
Matt Celeskey, Apokryltaros (vectorized by T. Michael Keesey), Mathilde
Cordellier, Alexandre Vong, Ignacio Contreras, Michael Scroggie,
Francisco Manuel Blanco (vectorized by T. Michael Keesey), Sidney
Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel),
Kent Elson Sorgon, Kamil S. Jaron, Katie S. Collins, Andrew A. Farke,
Oscar Sanisidro, T. Michael Keesey (vector) and Stuart Halliday
(photograph), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Doug Backlund (photo),
John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Chloé
Schmidt, FunkMonk, Caleb M. Brown, Kenneth Lacovara (vectorized by T.
Michael Keesey), S.Martini, B. Duygu Özpolat, Ieuan Jones, Aline M.
Ghilardi, Henry Lydecker, M Kolmann, Stanton F. Fink, vectorized by
Zimices, Bennet McComish, photo by Hans Hillewaert, Marie Russell, T.
Michael Keesey (after Masteraah), Noah Schlottman, photo from Casey
Dunn, Rebecca Groom, Nobu Tamura, vectorized by Zimices, T. Tischler,
Gopal Murali, Mattia Menchetti, Neil Kelley, Manabu Sakamoto, Hans
Hillewaert (vectorized by T. Michael Keesey), Fernando Carezzano, Felix
Vaux, Martin R. Smith, Sean McCann, Michelle Site, Henry Fairfield
Osborn, vectorized by Zimices, Zachary Quigley, Wayne Decatur,
Dr. Thomas G. Barnes, USFWS, Cristopher Silva, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Caroline Harding, MAF (vectorized by T. Michael Keesey),
T. Michael Keesey (photo by Bc999 \[Black crow\]), David Orr, Matt
Wilkins, Emil Schmidt (vectorized by Maxime Dahirel), Lukasiniho,
Fernando Campos De Domenico, V. Deepak, Mali’o Kodis, photograph by John
Slapcinsky, John Gould (vectorized by T. Michael Keesey), Caio
Bernardes, vectorized by Zimices, Dinah Challen, Juan Carlos Jerí,
Ludwik Gąsiorowski, Roger Witter, vectorized by Zimices, Mason McNair,
Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali
Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey, Vanessa Guerra,
Lily Hughes, Tyler Greenfield, Yan Wong from drawing in The Century
Dictionary (1911), Erika Schumacher, Ben Moon, Haplochromis (vectorized
by T. Michael Keesey), Crystal Maier, Harold N Eyster, Taro Maeda,
Margret Flinsch, vectorized by Zimices, Robert Bruce Horsfall
(vectorized by William Gearty), Julio Garza, Beth Reinke, Mercedes
Yrayzoz (vectorized by T. Michael Keesey), Jakovche, Josefine Bohr
Brask, Robert Hering, Adrian Reich, Stacy Spensley (Modified), Christoph
Schomburg, Scott Hartman (vectorized by T. Michael Keesey), Maxwell
Lefroy (vectorized by T. Michael Keesey), Charles R. Knight, vectorized
by Zimices, Mike Hanson, SecretJellyMan - from Mason McNair, Rafael
Maia, Benchill, Cathy, terngirl, Dmitry Bogdanov and FunkMonk
(vectorized by T. Michael Keesey), Michele Tobias, Noah Schlottman,
photo by Martin V. Sørensen, Baheerathan Murugavel, Esme Ashe-Jepson,
Smokeybjb (vectorized by T. Michael Keesey), Melissa Broussard,
SauropodomorphMonarch, Thea Boodhoo (photograph) and T. Michael Keesey
(vectorization), Peter Coxhead, Mathieu Pélissié, U.S. Fish and Wildlife
Service (illustration) and Timothy J. Bartley (silhouette), Emily Jane
McTavish, from
<http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>,
ArtFavor & annaleeblysse, Collin Gross, Bruno Maggia, Dmitry Bogdanov,
vectorized by Zimices, M. Antonio Todaro, Tobias Kånneby, Matteo Dal
Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey), Nobu Tamura,
JCGiron, Nobu Tamura (modified by T. Michael Keesey), Courtney
Rockenbach, Mathew Stewart, Mette Aumala, , Andrew A. Farke, shell lines
added by Yan Wong, Nicolas Mongiardino Koch, Aleksey Nagovitsyn
(vectorized by T. Michael Keesey), Matt Wilkins (photo by Patrick
Kavanagh), Sharon Wegner-Larsen, Konsta Happonen, from a CC-BY-NC image
by sokolkov2002 on iNaturalist, Conty (vectorized by T. Michael Keesey),
Matt Dempsey, Ghedo and T. Michael Keesey, Frank Denota, Mali’o Kodis,
image by Rebecca Ritger, Noah Schlottman, Julie Blommaert based on photo
by Sofdrakou, T. Michael Keesey (vectorization) and Larry Loos
(photography), Armin Reindl, James R. Spotila and Ray Chatterji,
Elisabeth Östman, Ingo Braasch, Ray Simpson (vectorized by T. Michael
Keesey), Cagri Cevrim, mystica, Xavier Giroux-Bougard, Aviceda (photo) &
T. Michael Keesey, Tyler Greenfield and Scott Hartman, Andrew A. Farke,
modified from original by H. Milne Edwards, Riccardo Percudani, Alex
Slavenko, Joseph Smit (modified by T. Michael Keesey), Craig Dylke,
Andreas Preuss / marauder, Yan Wong from drawing by Joseph Smit, Didier
Descouens (vectorized by T. Michael Keesey), NASA, xgirouxb, Bob
Goldstein, Vectorization:Jake Warner, Rene Martin, Ricardo Araújo, Johan
Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe, T.
Michael Keesey (after Heinrich Harder), Jack Mayer Wood, Mark Hofstetter
(vectorized by T. Michael Keesey), Louis Ranjard, Lindberg (vectorized
by T. Michael Keesey), Trond R. Oskars, Karina Garcia, Mali’o Kodis,
image from the “Proceedings of the Zoological Society of London”, M. A.
Broussard, Agnello Picorelli, Walter Vladimir, Inessa Voet, Robert Gay,
modifed from Olegivvit, Robert Bruce Horsfall, vectorized by Zimices,
Michael Scroggie, from original photograph by Gary M. Stolz, USFWS
(original photograph in public domain)., Renato Santos, Metalhead64
(vectorized by T. Michael Keesey), Joedison Rocha, Alexander
Schmidt-Lebuhn, Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Pollyanna von Knorring and T.
Michael Keesey, Kevin Sánchez

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    455.026559 |    448.973970 | Matt Crook                                                                                                                                                            |
|   2 |    188.799154 |    722.535095 | C. Camilo Julián-Caballero                                                                                                                                            |
|   3 |    838.961342 |    120.515404 | Gareth Monger                                                                                                                                                         |
|   4 |    864.935053 |    221.400695 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
|   5 |    315.024500 |    125.325732 | T. Michael Keesey                                                                                                                                                     |
|   6 |    807.664513 |     53.015752 | Conty                                                                                                                                                                 |
|   7 |    677.298476 |    349.808453 | Chris huh                                                                                                                                                             |
|   8 |    407.186784 |    719.280914 | Scott Hartman                                                                                                                                                         |
|   9 |    521.863722 |    295.394413 | Lisa M. “Pixxl” (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey       |
|  10 |    673.781941 |    601.729583 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
|  11 |    457.898713 |    142.719284 | Chris huh                                                                                                                                                             |
|  12 |    598.336813 |    681.919286 | Florian Pfaff                                                                                                                                                         |
|  13 |     77.949168 |    219.397527 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
|  14 |    886.432865 |    588.140152 | NA                                                                                                                                                                    |
|  15 |    748.980533 |    334.049976 | Mathew Callaghan                                                                                                                                                      |
|  16 |    182.125318 |    633.868516 | Zimices                                                                                                                                                               |
|  17 |    704.360516 |    728.395916 | Jimmy Bernot                                                                                                                                                          |
|  18 |    130.736054 |     86.742456 | (after Spotila 2004)                                                                                                                                                  |
|  19 |    544.966595 |     29.454651 | Smokeybjb                                                                                                                                                             |
|  20 |    627.272436 |    170.546884 | Campbell Fleming                                                                                                                                                      |
|  21 |    271.688413 |    403.976285 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
|  22 |     66.158540 |    427.757139 | T. Michael Keesey                                                                                                                                                     |
|  23 |    184.585181 |    197.913775 | FJDegrange                                                                                                                                                            |
|  24 |    628.110174 |    268.236377 | Daniel Stadtmauer                                                                                                                                                     |
|  25 |    266.364788 |    536.981634 | Jagged Fang Designs                                                                                                                                                   |
|  26 |    517.690937 |    598.512089 | Gareth Monger                                                                                                                                                         |
|  27 |    869.418509 |    415.696843 | Chase Brownstein                                                                                                                                                      |
|  28 |    312.400095 |    653.953557 | Cesar Julian                                                                                                                                                          |
|  29 |    625.606708 |    463.592938 | L. Shyamal                                                                                                                                                            |
|  30 |    779.824831 |    715.754787 | Kai R. Caspar                                                                                                                                                         |
|  31 |    257.787055 |    365.148581 | Steven Traver                                                                                                                                                         |
|  32 |    151.207290 |    363.960164 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
|  33 |    372.275219 |    269.434198 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  34 |    772.632397 |    537.209672 | Scott Hartman                                                                                                                                                         |
|  35 |    433.104160 |    697.349418 | Scott Hartman                                                                                                                                                         |
|  36 |    684.943387 |    105.137850 | Michele M Tobias                                                                                                                                                      |
|  37 |    257.098104 |     48.382204 | Chris huh                                                                                                                                                             |
|  38 |    886.201915 |    491.263683 | Chris huh                                                                                                                                                             |
|  39 |    938.362953 |     95.565012 | Anthony Caravaggi                                                                                                                                                     |
|  40 |     97.151002 |    553.824045 | Emily Willoughby                                                                                                                                                      |
|  41 |    919.905607 |    318.697043 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                               |
|  42 |    893.560133 |    672.926948 | Andy Wilson                                                                                                                                                           |
|  43 |     27.195896 |     60.663862 | NA                                                                                                                                                                    |
|  44 |    211.869095 |     23.051043 | Scott Hartman                                                                                                                                                         |
|  45 |    317.178782 |    568.664927 | Emily Willoughby                                                                                                                                                      |
|  46 |    750.536539 |    198.784748 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|  47 |    449.740240 |     94.720175 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  48 |     24.135607 |    652.908577 | Gareth Monger                                                                                                                                                         |
|  49 |    744.181539 |    435.369484 | Chris huh                                                                                                                                                             |
|  50 |    389.283226 |    615.944949 | Birgit Lang                                                                                                                                                           |
|  51 |    591.681294 |    756.289476 | Becky Barnes                                                                                                                                                          |
|  52 |     70.170873 |    744.646843 | Steven Coombs                                                                                                                                                         |
|  53 |    223.133731 |    312.380135 | Christine Axon                                                                                                                                                        |
|  54 |    282.094826 |    759.703284 | Michael P. Taylor                                                                                                                                                     |
|  55 |    851.353975 |    779.102348 | Shyamal                                                                                                                                                               |
|  56 |     64.677922 |    774.339129 | Markus A. Grohme                                                                                                                                                      |
|  57 |    209.574806 |    424.484844 | Margot Michaud                                                                                                                                                        |
|  58 |    358.822938 |     34.878451 | Zimices                                                                                                                                                               |
|  59 |    493.108543 |     53.219537 | Lip Kee Yap (vectorized by T. Michael Keesey)                                                                                                                         |
|  60 |    780.905466 |    484.899488 | Maija Karala                                                                                                                                                          |
|  61 |    940.465522 |    183.304719 | Margot Michaud                                                                                                                                                        |
|  62 |    585.468015 |     91.976402 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  63 |    913.626061 |    530.448588 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
|  64 |    446.226147 |    348.512541 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  65 |    167.567298 |    494.135918 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
|  66 |    579.856264 |    218.488878 | NA                                                                                                                                                                    |
|  67 |    455.200462 |    768.049681 | Scott Hartman                                                                                                                                                         |
|  68 |    565.683624 |    543.451833 | Jagged Fang Designs                                                                                                                                                   |
|  69 |    474.768409 |    649.197095 | Raven Amos                                                                                                                                                            |
|  70 |    950.242689 |    438.548500 | Jagged Fang Designs                                                                                                                                                   |
|  71 |    654.767814 |    321.163489 | Roberto Díaz Sibaja                                                                                                                                                   |
|  72 |    673.179143 |    397.958358 | Tasman Dixon                                                                                                                                                          |
|  73 |    261.452302 |    626.684681 | CNZdenek                                                                                                                                                              |
|  74 |    418.730753 |    207.021265 | Margot Michaud                                                                                                                                                        |
|  75 |    961.730401 |    739.765496 | Birgit Lang                                                                                                                                                           |
|  76 |    538.287460 |    506.069793 | Matt Crook                                                                                                                                                            |
|  77 |    221.211586 |    106.927924 | Matt Martyniuk                                                                                                                                                        |
|  78 |    869.853131 |    263.249806 | Chris huh                                                                                                                                                             |
|  79 |    370.464404 |    590.006805 | Carlos Cano-Barbacil                                                                                                                                                  |
|  80 |     23.176801 |    331.735793 | Mo Hassan                                                                                                                                                             |
|  81 |    687.440242 |    197.438270 | Scott Reid                                                                                                                                                            |
|  82 |    825.600847 |    645.913371 | Noah Schlottman, photo by Casey Dunn                                                                                                                                  |
|  83 |     33.844547 |    576.123048 | Terpsichores                                                                                                                                                          |
|  84 |    792.058065 |    140.043388 | Joanna Wolfe                                                                                                                                                          |
|  85 |    589.304872 |    570.631032 | Margot Michaud                                                                                                                                                        |
|  86 |    754.861110 |    301.712368 | Sarah Werning                                                                                                                                                         |
|  87 |    320.158675 |    512.920869 | B Kimmel                                                                                                                                                              |
|  88 |    105.268038 |    602.590930 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                          |
|  89 |    305.809138 |    720.319340 | Gareth Monger                                                                                                                                                         |
|  90 |    453.039443 |    228.257877 | T. Michael Keesey                                                                                                                                                     |
|  91 |    979.212974 |    211.889999 | Chuanixn Yu                                                                                                                                                           |
|  92 |     67.272485 |    654.440331 | NA                                                                                                                                                                    |
|  93 |    663.427677 |     14.245831 | Zimices                                                                                                                                                               |
|  94 |    665.735091 |    781.718216 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                                    |
|  95 |    731.433521 |    126.931212 | Ferran Sayol                                                                                                                                                          |
|  96 |    594.660774 |    598.999541 | Zimices                                                                                                                                                               |
|  97 |    145.182472 |     43.955227 | T. Michael Keesey                                                                                                                                                     |
|  98 |    397.304712 |    367.334637 | Iain Reid                                                                                                                                                             |
|  99 |    542.607158 |    169.517918 | Chris huh                                                                                                                                                             |
| 100 |    563.385325 |    679.728209 | Maxime Dahirel                                                                                                                                                        |
| 101 |    181.756617 |    560.093994 | Steven Traver                                                                                                                                                         |
| 102 |     83.953159 |     35.272241 | Jagged Fang Designs                                                                                                                                                   |
| 103 |    334.424039 |    791.874458 | Cesar Julian                                                                                                                                                          |
| 104 |    165.427114 |    523.904010 | Steven Traver                                                                                                                                                         |
| 105 |    631.683711 |    681.395286 | Jan Sevcik (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey            |
| 106 |    944.843446 |     28.631066 | Zimices                                                                                                                                                               |
| 107 |    404.929862 |    787.509814 | Dean Schnabel                                                                                                                                                         |
| 108 |    442.528698 |    344.204832 | Scott Hartman                                                                                                                                                         |
| 109 |     64.356602 |    764.594613 | Roberto Díaz Sibaja                                                                                                                                                   |
| 110 |    733.783924 |    651.381829 | Hugo Gruson                                                                                                                                                           |
| 111 |    144.827734 |    776.826466 | Jaime Headden                                                                                                                                                         |
| 112 |    245.372548 |    559.091257 | Jagged Fang Designs                                                                                                                                                   |
| 113 |    527.651583 |    424.136276 | Birgit Lang                                                                                                                                                           |
| 114 |    999.295771 |    646.845498 | Zimices                                                                                                                                                               |
| 115 |    511.719845 |     12.469857 | Dmitry Bogdanov                                                                                                                                                       |
| 116 |    283.102437 |    201.987500 | Zimices                                                                                                                                                               |
| 117 |    775.863959 |    592.693914 | Ferran Sayol                                                                                                                                                          |
| 118 |     37.012918 |    300.849618 | Matt Crook                                                                                                                                                            |
| 119 |   1001.135004 |    412.975300 | Gareth Monger                                                                                                                                                         |
| 120 |    807.616656 |    681.822286 | Scott Hartman                                                                                                                                                         |
| 121 |    831.889806 |    664.566300 | Matt Crook                                                                                                                                                            |
| 122 |    840.945045 |     99.282271 | NA                                                                                                                                                                    |
| 123 |    633.405547 |    661.536329 | Birgit Lang                                                                                                                                                           |
| 124 |    979.963231 |    698.696853 | Tauana J. Cunha                                                                                                                                                       |
| 125 |    235.244308 |    240.470083 | Rainer Schoch                                                                                                                                                         |
| 126 |    331.242651 |    211.220889 | Yan Wong                                                                                                                                                              |
| 127 |     63.524098 |     13.510109 | Zimices                                                                                                                                                               |
| 128 |    998.728358 |    505.438583 | Gareth Monger                                                                                                                                                         |
| 129 |    883.213320 |    749.509397 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 130 |    314.010709 |    671.640720 | Dean Schnabel                                                                                                                                                         |
| 131 |    255.730667 |    246.265330 | Kanchi Nanjo                                                                                                                                                          |
| 132 |    935.322491 |    210.969773 | Matt Crook                                                                                                                                                            |
| 133 |    844.114617 |      9.237431 | Scott Hartman                                                                                                                                                         |
| 134 |    142.805161 |    227.554462 | Ferran Sayol                                                                                                                                                          |
| 135 |    567.904081 |    619.566848 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 136 |    435.148719 |    244.156428 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 137 |    415.110748 |    672.425200 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 138 |     27.121952 |    258.587879 | Maxime Dahirel                                                                                                                                                        |
| 139 |    255.951328 |    594.579315 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 140 |    675.963527 |    226.237539 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 141 |    199.182866 |    358.009834 | Mathew Wedel                                                                                                                                                          |
| 142 |    977.840748 |    403.001126 | Steven Traver                                                                                                                                                         |
| 143 |    713.503632 |    191.577724 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 144 |    168.105110 |    136.234528 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 145 |    364.423388 |    531.878818 | Lafage                                                                                                                                                                |
| 146 |    626.529293 |    789.410056 | Zimices                                                                                                                                                               |
| 147 |    550.174524 |    722.730999 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 148 |    707.205176 |     95.385233 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 149 |    954.928861 |    228.824933 | Matt Crook                                                                                                                                                            |
| 150 |    669.878889 |    522.547401 | Gareth Monger                                                                                                                                                         |
| 151 |    656.791528 |     53.893605 | Tauana J. Cunha                                                                                                                                                       |
| 152 |    403.343793 |    252.955950 | Matt Celeskey                                                                                                                                                         |
| 153 |    986.158015 |    247.765339 | Gareth Monger                                                                                                                                                         |
| 154 |     93.535501 |    283.848435 | Jagged Fang Designs                                                                                                                                                   |
| 155 |    391.707036 |    552.929801 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 156 |    849.732474 |    174.109728 | Matt Crook                                                                                                                                                            |
| 157 |    168.473492 |    541.891278 | NA                                                                                                                                                                    |
| 158 |    175.922558 |    582.875130 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                        |
| 159 |     14.233904 |    358.564193 | Ferran Sayol                                                                                                                                                          |
| 160 |   1002.087301 |    366.344302 | Chris huh                                                                                                                                                             |
| 161 |    961.747171 |    271.521575 | Mathilde Cordellier                                                                                                                                                   |
| 162 |    165.134965 |     56.378520 | NA                                                                                                                                                                    |
| 163 |    682.807184 |     17.805421 | Alexandre Vong                                                                                                                                                        |
| 164 |    468.716011 |    576.682996 | Matt Crook                                                                                                                                                            |
| 165 |    229.855571 |    676.445799 | Jagged Fang Designs                                                                                                                                                   |
| 166 |   1000.731449 |    289.961788 | Ignacio Contreras                                                                                                                                                     |
| 167 |    805.624277 |    418.762308 | Michael Scroggie                                                                                                                                                      |
| 168 |    731.746387 |    316.394041 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                             |
| 169 |    712.266661 |    638.187786 | T. Michael Keesey                                                                                                                                                     |
| 170 |    133.903527 |     31.487596 | Gareth Monger                                                                                                                                                         |
| 171 |   1011.431014 |    719.694426 | Steven Traver                                                                                                                                                         |
| 172 |      7.671822 |    455.283884 | Markus A. Grohme                                                                                                                                                      |
| 173 |    790.447682 |    399.758173 | Scott Hartman                                                                                                                                                         |
| 174 |     58.058754 |     36.504987 | Zimices                                                                                                                                                               |
| 175 |     63.284539 |    600.516489 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                         |
| 176 |    934.278839 |    683.417643 | Kent Elson Sorgon                                                                                                                                                     |
| 177 |    115.871255 |    623.406486 | Ferran Sayol                                                                                                                                                          |
| 178 |    165.165455 |    573.046610 | Kamil S. Jaron                                                                                                                                                        |
| 179 |    500.985753 |    419.654076 | Gareth Monger                                                                                                                                                         |
| 180 |   1016.081910 |    552.041863 | Margot Michaud                                                                                                                                                        |
| 181 |    807.468268 |    234.163043 | Katie S. Collins                                                                                                                                                      |
| 182 |     50.075892 |     43.572142 | Andrew A. Farke                                                                                                                                                       |
| 183 |    360.218771 |    195.471181 | Oscar Sanisidro                                                                                                                                                       |
| 184 |    431.494027 |    300.134881 | T. Michael Keesey (vector) and Stuart Halliday (photograph)                                                                                                           |
| 185 |    428.074385 |    788.673207 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 186 |    185.417609 |    234.978240 | NA                                                                                                                                                                    |
| 187 |   1007.861301 |     89.796687 | Doug Backlund (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 188 |    231.528649 |    208.524318 | Tasman Dixon                                                                                                                                                          |
| 189 |    765.840977 |    794.803873 | Smokeybjb                                                                                                                                                             |
| 190 |    583.783793 |    333.334449 | Darren Naish (vectorized by T. Michael Keesey)                                                                                                                        |
| 191 |    447.508868 |    255.789831 | Zimices                                                                                                                                                               |
| 192 |    265.776979 |    388.821604 | Chloé Schmidt                                                                                                                                                         |
| 193 |    124.786055 |    686.738541 | FunkMonk                                                                                                                                                              |
| 194 |    113.849546 |    459.470040 | Andy Wilson                                                                                                                                                           |
| 195 |    852.433004 |     49.747403 | Caleb M. Brown                                                                                                                                                        |
| 196 |    284.133318 |    697.698289 | Markus A. Grohme                                                                                                                                                      |
| 197 |     73.912612 |     48.681503 | Kenneth Lacovara (vectorized by T. Michael Keesey)                                                                                                                    |
| 198 |    890.350463 |     49.314456 | Zimices                                                                                                                                                               |
| 199 |   1014.405469 |    283.303525 | S.Martini                                                                                                                                                             |
| 200 |    110.009305 |    327.486890 | T. Michael Keesey                                                                                                                                                     |
| 201 |    978.980731 |    469.929544 | B. Duygu Özpolat                                                                                                                                                      |
| 202 |    696.931501 |    592.214883 | Chris huh                                                                                                                                                             |
| 203 |    945.099484 |    523.981283 | Iain Reid                                                                                                                                                             |
| 204 |    830.646144 |     60.737902 | Markus A. Grohme                                                                                                                                                      |
| 205 |    137.647143 |    465.900533 | Ieuan Jones                                                                                                                                                           |
| 206 |    410.575362 |    503.714327 | Scott Hartman                                                                                                                                                         |
| 207 |    986.430587 |    679.405629 | Aline M. Ghilardi                                                                                                                                                     |
| 208 |      7.640159 |    128.402331 | NA                                                                                                                                                                    |
| 209 |    783.097797 |    219.408094 | Henry Lydecker                                                                                                                                                        |
| 210 |   1012.068177 |    193.643977 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 211 |    762.552622 |    111.565099 | M Kolmann                                                                                                                                                             |
| 212 |    418.712826 |    741.628267 | Carlos Cano-Barbacil                                                                                                                                                  |
| 213 |    281.344605 |    391.101438 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 214 |    221.461304 |    585.356534 | NA                                                                                                                                                                    |
| 215 |    689.233055 |    545.306609 | Stanton F. Fink, vectorized by Zimices                                                                                                                                |
| 216 |    574.203820 |    598.060252 | Sarah Werning                                                                                                                                                         |
| 217 |    950.388474 |     40.055024 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 218 |    746.505227 |    600.534574 | Marie Russell                                                                                                                                                         |
| 219 |    962.327446 |    770.141229 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 220 |    286.239175 |    506.963224 | Markus A. Grohme                                                                                                                                                      |
| 221 |    264.760143 |    580.032180 | Matt Crook                                                                                                                                                            |
| 222 |    383.149978 |    525.936677 | Tasman Dixon                                                                                                                                                          |
| 223 |    106.392029 |    722.325662 | Noah Schlottman, photo from Casey Dunn                                                                                                                                |
| 224 |    712.338628 |    459.384434 | Rebecca Groom                                                                                                                                                         |
| 225 |    441.305363 |    205.746550 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 226 |    288.258948 |    264.190694 | T. Tischler                                                                                                                                                           |
| 227 |    548.515993 |    706.186367 | Steven Traver                                                                                                                                                         |
| 228 |     59.906786 |    140.188745 | Gareth Monger                                                                                                                                                         |
| 229 |    436.041549 |     30.047140 | Zimices                                                                                                                                                               |
| 230 |    562.224880 |     40.318945 | Sarah Werning                                                                                                                                                         |
| 231 |    557.093248 |    150.426405 | Gopal Murali                                                                                                                                                          |
| 232 |   1014.677334 |    124.441083 | Emily Willoughby                                                                                                                                                      |
| 233 |    158.712573 |    206.112572 | Maija Karala                                                                                                                                                          |
| 234 |    771.206904 |    411.728781 | Matt Crook                                                                                                                                                            |
| 235 |    951.878708 |     66.895457 | Mattia Menchetti                                                                                                                                                      |
| 236 |    314.817288 |    301.395811 | NA                                                                                                                                                                    |
| 237 |    986.646511 |    146.166150 | Margot Michaud                                                                                                                                                        |
| 238 |    144.748785 |     18.663788 | Terpsichores                                                                                                                                                          |
| 239 |    321.901653 |    296.804087 | Jagged Fang Designs                                                                                                                                                   |
| 240 |    316.314031 |     51.453397 | Steven Traver                                                                                                                                                         |
| 241 |    524.702737 |    735.365310 | Neil Kelley                                                                                                                                                           |
| 242 |    710.458725 |      6.070119 | Manabu Sakamoto                                                                                                                                                       |
| 243 |    263.792866 |    181.864049 | Kai R. Caspar                                                                                                                                                         |
| 244 |    478.950856 |    748.715003 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 245 |    127.110666 |    783.795768 | Markus A. Grohme                                                                                                                                                      |
| 246 |     29.191661 |    381.826953 | Kamil S. Jaron                                                                                                                                                        |
| 247 |     75.315613 |    715.873806 | Fernando Carezzano                                                                                                                                                    |
| 248 |    468.519391 |    248.073144 | T. Michael Keesey                                                                                                                                                     |
| 249 |    666.603846 |    153.312096 | NA                                                                                                                                                                    |
| 250 |     91.465173 |    724.291265 | Margot Michaud                                                                                                                                                        |
| 251 |     81.983187 |    693.562479 | Jagged Fang Designs                                                                                                                                                   |
| 252 |    141.641277 |    134.762503 | Michele M Tobias                                                                                                                                                      |
| 253 |   1007.798148 |     48.683805 | Felix Vaux                                                                                                                                                            |
| 254 |    293.306542 |    106.449660 | Martin R. Smith                                                                                                                                                       |
| 255 |    909.969268 |     34.180415 | Sean McCann                                                                                                                                                           |
| 256 |    996.807033 |    556.043139 | Andrew A. Farke                                                                                                                                                       |
| 257 |     39.051081 |    181.243480 | Matt Crook                                                                                                                                                            |
| 258 |    925.687776 |    709.016421 | Michelle Site                                                                                                                                                         |
| 259 |    128.622854 |    409.065332 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 260 |    686.038174 |    459.561034 | Zachary Quigley                                                                                                                                                       |
| 261 |     39.548310 |    584.465279 | Matt Crook                                                                                                                                                            |
| 262 |    169.462367 |    259.358330 | L. Shyamal                                                                                                                                                            |
| 263 |   1011.034219 |    178.050960 | Wayne Decatur                                                                                                                                                         |
| 264 |    978.602150 |    504.076056 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 265 |    293.475976 |    404.667772 | Matt Martyniuk                                                                                                                                                        |
| 266 |    260.696847 |    274.718140 | Markus A. Grohme                                                                                                                                                      |
| 267 |    130.065634 |    590.300502 | Andrew A. Farke                                                                                                                                                       |
| 268 |    972.518266 |    644.762359 | Becky Barnes                                                                                                                                                          |
| 269 |    233.444222 |    360.419548 | Katie S. Collins                                                                                                                                                      |
| 270 |    630.369268 |    220.816998 | Cristopher Silva                                                                                                                                                      |
| 271 |    734.457538 |    591.590518 | Andy Wilson                                                                                                                                                           |
| 272 |     13.573177 |    210.798063 | Matt Crook                                                                                                                                                            |
| 273 |    821.940338 |      7.221032 | Margot Michaud                                                                                                                                                        |
| 274 |    587.635980 |    463.587156 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 275 |    923.257295 |     45.871081 | NA                                                                                                                                                                    |
| 276 |    143.784349 |    198.437766 | Caroline Harding, MAF (vectorized by T. Michael Keesey)                                                                                                               |
| 277 |    934.938673 |    646.362300 | Kai R. Caspar                                                                                                                                                         |
| 278 |    149.429135 |    267.908481 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 279 |    913.901137 |    117.928806 | Jagged Fang Designs                                                                                                                                                   |
| 280 |    915.840034 |    472.125423 | Margot Michaud                                                                                                                                                        |
| 281 |    968.662556 |    229.249046 | Ferran Sayol                                                                                                                                                          |
| 282 |    899.045020 |    457.479305 | David Orr                                                                                                                                                             |
| 283 |    323.961299 |    534.425193 | Chris huh                                                                                                                                                             |
| 284 |     24.105127 |    413.773259 | Matt Wilkins                                                                                                                                                          |
| 285 |    245.345808 |    182.065027 | Gareth Monger                                                                                                                                                         |
| 286 |     77.234971 |    700.692935 | Margot Michaud                                                                                                                                                        |
| 287 |    610.463849 |    618.560087 | Chris huh                                                                                                                                                             |
| 288 |    730.857605 |     27.357107 | Emil Schmidt (vectorized by Maxime Dahirel)                                                                                                                           |
| 289 |     40.155949 |    475.695785 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 290 |    324.932811 |    760.509805 | Jagged Fang Designs                                                                                                                                                   |
| 291 |     19.328047 |    438.362245 | Andy Wilson                                                                                                                                                           |
| 292 |    468.037141 |    179.872230 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 293 |    864.181211 |    443.944952 | Matt Crook                                                                                                                                                            |
| 294 |    870.532086 |    145.858317 | Anthony Caravaggi                                                                                                                                                     |
| 295 |    133.191222 |    674.433272 | Martin R. Smith                                                                                                                                                       |
| 296 |      8.792607 |    698.294680 | Chris huh                                                                                                                                                             |
| 297 |    612.153562 |    783.978134 | Emily Willoughby                                                                                                                                                      |
| 298 |    887.782378 |    628.727019 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 299 |    494.606870 |    731.173815 | Ferran Sayol                                                                                                                                                          |
| 300 |    882.611892 |     11.560124 | Margot Michaud                                                                                                                                                        |
| 301 |    255.308778 |    289.421875 | Jagged Fang Designs                                                                                                                                                   |
| 302 |    368.645562 |    480.494019 | T. Michael Keesey                                                                                                                                                     |
| 303 |    592.276928 |    370.951797 | Birgit Lang                                                                                                                                                           |
| 304 |    351.554733 |    733.904286 | Gareth Monger                                                                                                                                                         |
| 305 |    106.283940 |    148.357359 | Joanna Wolfe                                                                                                                                                          |
| 306 |    278.987566 |    411.889013 | Jagged Fang Designs                                                                                                                                                   |
| 307 |    523.345759 |    685.943486 | Margot Michaud                                                                                                                                                        |
| 308 |    569.702730 |     14.077767 | NA                                                                                                                                                                    |
| 309 |    404.693719 |    577.521547 | Margot Michaud                                                                                                                                                        |
| 310 |    696.343910 |    275.136262 | FunkMonk                                                                                                                                                              |
| 311 |    980.012340 |     19.381215 | Markus A. Grohme                                                                                                                                                      |
| 312 |    957.852138 |    491.221036 | Lukasiniho                                                                                                                                                            |
| 313 |    764.615632 |    128.501125 | Rebecca Groom                                                                                                                                                         |
| 314 |    320.056504 |    774.958149 | Jagged Fang Designs                                                                                                                                                   |
| 315 |    808.520221 |    543.506286 | Zimices                                                                                                                                                               |
| 316 |    385.540441 |    160.483603 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 317 |    710.095853 |     87.467953 | Fernando Campos De Domenico                                                                                                                                           |
| 318 |    484.369921 |    619.525454 | V. Deepak                                                                                                                                                             |
| 319 |    605.006499 |    105.034724 | Jagged Fang Designs                                                                                                                                                   |
| 320 |     88.512243 |    620.370947 | Ignacio Contreras                                                                                                                                                     |
| 321 |    566.822868 |    171.127336 | Margot Michaud                                                                                                                                                        |
| 322 |    502.841594 |     52.414273 | Katie S. Collins                                                                                                                                                      |
| 323 |    305.947607 |    242.375399 | Kanchi Nanjo                                                                                                                                                          |
| 324 |    767.489790 |    149.420335 | Mali’o Kodis, photograph by John Slapcinsky                                                                                                                           |
| 325 |    602.946084 |    537.207283 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 326 |    713.768961 |    606.855677 | Scott Hartman                                                                                                                                                         |
| 327 |    846.773910 |    681.039262 | Scott Hartman                                                                                                                                                         |
| 328 |    324.409397 |    684.398346 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 329 |    989.800900 |    106.392744 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 330 |    425.219329 |     45.543451 | Dinah Challen                                                                                                                                                         |
| 331 |    324.935508 |    588.971112 | T. Michael Keesey (after Masteraah)                                                                                                                                   |
| 332 |      9.824075 |    255.885580 | Carlos Cano-Barbacil                                                                                                                                                  |
| 333 |    234.629493 |    142.711734 | Matt Crook                                                                                                                                                            |
| 334 |    921.192579 |    774.401486 | Juan Carlos Jerí                                                                                                                                                      |
| 335 |    905.879411 |    144.145667 | Ludwik Gąsiorowski                                                                                                                                                    |
| 336 |   1009.573393 |    454.481796 | Ludwik Gąsiorowski                                                                                                                                                    |
| 337 |    909.550465 |    445.365257 | Chris huh                                                                                                                                                             |
| 338 |    452.862635 |    734.704030 | Roger Witter, vectorized by Zimices                                                                                                                                   |
| 339 |   1016.829459 |    773.099598 | Matt Crook                                                                                                                                                            |
| 340 |    987.004773 |     38.665365 | Mason McNair                                                                                                                                                          |
| 341 |    741.134379 |    501.316129 | Zimices                                                                                                                                                               |
| 342 |    726.698384 |     98.771739 | T. Michael Keesey                                                                                                                                                     |
| 343 |    435.665578 |      8.289300 | Steven Traver                                                                                                                                                         |
| 344 |    986.710481 |    348.998196 | Lukasiniho                                                                                                                                                            |
| 345 |    220.406656 |    357.544839 | Maxime Dahirel                                                                                                                                                        |
| 346 |      9.192863 |    539.133359 | Margot Michaud                                                                                                                                                        |
| 347 |    298.286635 |    778.686168 | Ferran Sayol                                                                                                                                                          |
| 348 |    129.545785 |    386.946287 | Hanyong Pu, Yoshitsugu Kobayashi, Junchang Lü, Li Xu, Yanhua Wu, Huali Chang, Jiming Zhang, Songhai Jia & T. Michael Keesey                                           |
| 349 |    835.757379 |    278.868424 | NA                                                                                                                                                                    |
| 350 |     32.164067 |    529.798564 | Matt Crook                                                                                                                                                            |
| 351 |     16.445245 |    312.312568 | T. Michael Keesey                                                                                                                                                     |
| 352 |    385.467859 |    684.211676 | Vanessa Guerra                                                                                                                                                        |
| 353 |    736.189089 |    103.922512 | Lily Hughes                                                                                                                                                           |
| 354 |    439.163888 |     75.497109 | Ferran Sayol                                                                                                                                                          |
| 355 |    641.335796 |     34.020917 | Zimices                                                                                                                                                               |
| 356 |    229.861418 |    282.584841 | Tyler Greenfield                                                                                                                                                      |
| 357 |    517.690481 |    382.366441 | Jaime Headden                                                                                                                                                         |
| 358 |    404.994930 |    680.473501 | L. Shyamal                                                                                                                                                            |
| 359 |    190.713572 |    118.595601 | Margot Michaud                                                                                                                                                        |
| 360 |    265.670385 |     79.884215 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                                |
| 361 |    133.096289 |    511.921677 | Tauana J. Cunha                                                                                                                                                       |
| 362 |    364.781386 |    578.295160 | NA                                                                                                                                                                    |
| 363 |    801.785525 |    658.623902 | Erika Schumacher                                                                                                                                                      |
| 364 |    970.612939 |     27.784678 | Ferran Sayol                                                                                                                                                          |
| 365 |     81.972568 |    592.313583 | Zimices                                                                                                                                                               |
| 366 |    636.348511 |     19.702054 | Manabu Sakamoto                                                                                                                                                       |
| 367 |    726.524700 |    272.678202 | Margot Michaud                                                                                                                                                        |
| 368 |    588.388835 |    731.325838 | Ben Moon                                                                                                                                                              |
| 369 |    994.566640 |    227.805455 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 370 |     46.650786 |    263.165433 | Scott Hartman                                                                                                                                                         |
| 371 |    692.663452 |    483.440752 | Zimices                                                                                                                                                               |
| 372 |    715.950261 |    498.569154 | Steven Traver                                                                                                                                                         |
| 373 |    333.280981 |    311.102868 | Carlos Cano-Barbacil                                                                                                                                                  |
| 374 |     95.721659 |    784.584619 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 375 |    201.645465 |    272.319093 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 376 |    282.215772 |    232.156589 | Scott Hartman                                                                                                                                                         |
| 377 |    361.207085 |    509.811003 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 378 |    763.586325 |    450.893692 | Jagged Fang Designs                                                                                                                                                   |
| 379 |   1005.063247 |    388.592239 | Crystal Maier                                                                                                                                                         |
| 380 |    100.384868 |    655.616512 | Gareth Monger                                                                                                                                                         |
| 381 |    372.231019 |    675.491735 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 382 |   1013.087773 |    525.396364 | Ferran Sayol                                                                                                                                                          |
| 383 |    890.395614 |    149.801579 | Harold N Eyster                                                                                                                                                       |
| 384 |    630.888801 |    603.513085 | Taro Maeda                                                                                                                                                            |
| 385 |    846.764980 |    369.277953 | Scott Hartman                                                                                                                                                         |
| 386 |    779.551607 |    780.069658 | T. Michael Keesey                                                                                                                                                     |
| 387 |    645.735612 |    752.063654 | Scott Hartman                                                                                                                                                         |
| 388 |    532.775789 |    153.273962 | Matt Crook                                                                                                                                                            |
| 389 |    200.594131 |     91.675402 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
| 390 |    839.312305 |    388.172738 | Gareth Monger                                                                                                                                                         |
| 391 |    438.926499 |    589.705934 | Margot Michaud                                                                                                                                                        |
| 392 |    646.341250 |    626.322538 | Margret Flinsch, vectorized by Zimices                                                                                                                                |
| 393 |    454.208838 |    558.290393 | Chris huh                                                                                                                                                             |
| 394 |    804.078623 |    158.649936 | Zimices                                                                                                                                                               |
| 395 |    199.378234 |    757.828300 | Birgit Lang                                                                                                                                                           |
| 396 |    392.048864 |    482.038780 | Jagged Fang Designs                                                                                                                                                   |
| 397 |    800.827608 |    298.845668 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 398 |    732.626784 |    233.347369 | NA                                                                                                                                                                    |
| 399 |    806.266476 |    272.567947 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                                  |
| 400 |     41.606198 |    161.163687 | Julio Garza                                                                                                                                                           |
| 401 |    440.907807 |    291.798041 | Beth Reinke                                                                                                                                                           |
| 402 |    813.180087 |    318.355917 | Mercedes Yrayzoz (vectorized by T. Michael Keesey)                                                                                                                    |
| 403 |    147.283000 |    737.200556 | Jakovche                                                                                                                                                              |
| 404 |    184.683845 |    397.054264 | Margot Michaud                                                                                                                                                        |
| 405 |    724.359074 |    780.212650 | Josefine Bohr Brask                                                                                                                                                   |
| 406 |     46.073228 |    150.057934 | Crystal Maier                                                                                                                                                         |
| 407 |    238.256137 |    288.143756 | Scott Hartman                                                                                                                                                         |
| 408 |    386.425030 |    180.964695 | Robert Hering                                                                                                                                                         |
| 409 |    973.304545 |    448.864931 | Matt Crook                                                                                                                                                            |
| 410 |    395.251049 |    452.407800 | Chris huh                                                                                                                                                             |
| 411 |    627.925247 |    169.822332 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 412 |    818.818097 |     96.699669 | Michelle Site                                                                                                                                                         |
| 413 |    856.708577 |    722.797552 | Zimices                                                                                                                                                               |
| 414 |    663.354994 |    135.778677 | Adrian Reich                                                                                                                                                          |
| 415 |    523.145385 |    719.583485 | C. Camilo Julián-Caballero                                                                                                                                            |
| 416 |    227.032326 |    664.325260 | Margot Michaud                                                                                                                                                        |
| 417 |    226.354227 |    544.842500 | Birgit Lang                                                                                                                                                           |
| 418 |    200.779730 |    577.760232 | Dmitry Bogdanov                                                                                                                                                       |
| 419 |    715.978400 |    788.191184 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 420 |    484.845611 |    721.740491 | Gareth Monger                                                                                                                                                         |
| 421 |    669.495504 |    744.014971 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 422 |    380.680569 |    117.751266 | Katie S. Collins                                                                                                                                                      |
| 423 |    572.246280 |    411.699645 | Kai R. Caspar                                                                                                                                                         |
| 424 |     14.052351 |    138.799106 | Zimices                                                                                                                                                               |
| 425 |    916.961949 |    241.678673 | Ferran Sayol                                                                                                                                                          |
| 426 |    136.453166 |    552.134435 | Maija Karala                                                                                                                                                          |
| 427 |    284.788602 |    720.541442 | Stacy Spensley (Modified)                                                                                                                                             |
| 428 |    881.158261 |    794.072931 | Christoph Schomburg                                                                                                                                                   |
| 429 |    840.597228 |    296.685179 | Margot Michaud                                                                                                                                                        |
| 430 |    258.677460 |    353.262297 | Matt Crook                                                                                                                                                            |
| 431 |    992.954188 |    270.532989 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 432 |    388.541621 |    325.953848 | Maxwell Lefroy (vectorized by T. Michael Keesey)                                                                                                                      |
| 433 |    580.063093 |    368.919183 | T. Michael Keesey                                                                                                                                                     |
| 434 |    569.757824 |    718.984632 | Matt Crook                                                                                                                                                            |
| 435 |    284.347240 |    284.560476 | Steven Traver                                                                                                                                                         |
| 436 |    256.878079 |    217.346020 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 437 |    706.951838 |     72.684659 | Margot Michaud                                                                                                                                                        |
| 438 |    986.105306 |    453.004616 | Birgit Lang                                                                                                                                                           |
| 439 |    287.229360 |    628.276580 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 440 |   1012.023802 |    334.729990 | Cesar Julian                                                                                                                                                          |
| 441 |    263.978286 |    485.045371 | Matt Celeskey                                                                                                                                                         |
| 442 |    937.960694 |     72.659632 | Mike Hanson                                                                                                                                                           |
| 443 |    329.317384 |    543.613600 | T. Michael Keesey                                                                                                                                                     |
| 444 |    562.769519 |    440.412552 | Tasman Dixon                                                                                                                                                          |
| 445 |    914.292222 |     18.686464 | Ferran Sayol                                                                                                                                                          |
| 446 |    244.412172 |    100.059549 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 447 |    518.337891 |    676.405800 | NA                                                                                                                                                                    |
| 448 |    100.755325 |    702.112882 | Tasman Dixon                                                                                                                                                          |
| 449 |    894.698176 |     92.537366 | Maija Karala                                                                                                                                                          |
| 450 |    641.111434 |    125.922493 | Margot Michaud                                                                                                                                                        |
| 451 |    367.172029 |    537.044591 | Carlos Cano-Barbacil                                                                                                                                                  |
| 452 |    825.932512 |    692.504908 | Ferran Sayol                                                                                                                                                          |
| 453 |    621.039315 |     42.722169 | SecretJellyMan - from Mason McNair                                                                                                                                    |
| 454 |    643.837131 |    145.326191 | T. Michael Keesey                                                                                                                                                     |
| 455 |    421.624705 |    295.536888 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 456 |    515.174816 |    334.057860 | Chuanixn Yu                                                                                                                                                           |
| 457 |    672.341058 |    439.860239 | Scott Hartman                                                                                                                                                         |
| 458 |    199.011421 |    658.320576 | Shyamal                                                                                                                                                               |
| 459 |    210.104869 |    744.455621 | Scott Hartman                                                                                                                                                         |
| 460 |    591.843008 |    695.666464 | Rafael Maia                                                                                                                                                           |
| 461 |    603.734217 |    579.563464 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 462 |    168.889299 |    124.207226 | Scott Hartman                                                                                                                                                         |
| 463 |    293.142673 |    544.462279 | Benchill                                                                                                                                                              |
| 464 |    551.458266 |    126.181371 | Cathy                                                                                                                                                                 |
| 465 |     14.618485 |    482.127945 | Steven Traver                                                                                                                                                         |
| 466 |    870.033740 |    735.364370 | Carlos Cano-Barbacil                                                                                                                                                  |
| 467 |    211.351827 |    398.205924 | terngirl                                                                                                                                                              |
| 468 |   1004.601691 |    160.963462 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                                        |
| 469 |    952.345265 |    420.173701 | Hugo Gruson                                                                                                                                                           |
| 470 |    238.246527 |    578.547351 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 471 |    915.047548 |     66.873071 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 472 |    996.695290 |    119.708265 | Scott Reid                                                                                                                                                            |
| 473 |    491.294593 |    176.119155 | Michele Tobias                                                                                                                                                        |
| 474 |    737.618819 |    728.964854 | Noah Schlottman, photo by Martin V. Sørensen                                                                                                                          |
| 475 |    700.178827 |    563.687431 | Baheerathan Murugavel                                                                                                                                                 |
| 476 |    852.995175 |    307.481604 | NA                                                                                                                                                                    |
| 477 |    910.164799 |    614.939110 | Gareth Monger                                                                                                                                                         |
| 478 |    686.151710 |     42.322504 | C. Camilo Julián-Caballero                                                                                                                                            |
| 479 |    733.879422 |     12.419125 | Harold N Eyster                                                                                                                                                       |
| 480 |    643.030903 |     97.091482 | Esme Ashe-Jepson                                                                                                                                                      |
| 481 |    633.186487 |    519.469316 | Cesar Julian                                                                                                                                                          |
| 482 |    410.859325 |    414.847481 | Smokeybjb (vectorized by T. Michael Keesey)                                                                                                                           |
| 483 |     22.183480 |    192.118207 | Melissa Broussard                                                                                                                                                     |
| 484 |      8.229663 |    496.586693 | Baheerathan Murugavel                                                                                                                                                 |
| 485 |    935.025445 |    747.082825 | Scott Hartman                                                                                                                                                         |
| 486 |    498.812467 |    678.682164 | SauropodomorphMonarch                                                                                                                                                 |
| 487 |    467.458962 |    684.540575 | NA                                                                                                                                                                    |
| 488 |    421.371599 |    609.573619 | Dmitry Bogdanov                                                                                                                                                       |
| 489 |   1015.950361 |    675.182727 | David Orr                                                                                                                                                             |
| 490 |    574.885248 |     54.702251 | Matt Wilkins                                                                                                                                                          |
| 491 |    337.335346 |    335.286803 | Thea Boodhoo (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 492 |    819.066160 |    737.169423 | NA                                                                                                                                                                    |
| 493 |    596.848733 |    166.467678 | Peter Coxhead                                                                                                                                                         |
| 494 |   1014.157551 |    709.802897 | Mo Hassan                                                                                                                                                             |
| 495 |    685.767871 |    761.472159 | NA                                                                                                                                                                    |
| 496 |    228.091920 |    782.638684 | Andy Wilson                                                                                                                                                           |
| 497 |    212.243877 |    556.889456 | Matt Crook                                                                                                                                                            |
| 498 |    642.039081 |    785.602854 | Scott Hartman                                                                                                                                                         |
| 499 |    406.551416 |    237.470509 | Jagged Fang Designs                                                                                                                                                   |
| 500 |    771.639930 |    623.581911 | Michele M Tobias                                                                                                                                                      |
| 501 |    734.909656 |    768.234070 | T. Michael Keesey                                                                                                                                                     |
| 502 |    116.535535 |    522.463421 | Kamil S. Jaron                                                                                                                                                        |
| 503 |    593.385682 |    390.820652 | Gareth Monger                                                                                                                                                         |
| 504 |    119.805703 |    444.267626 | Mathieu Pélissié                                                                                                                                                      |
| 505 |    542.410892 |     46.041542 | Matt Crook                                                                                                                                                            |
| 506 |    162.639288 |    286.135534 | Jagged Fang Designs                                                                                                                                                   |
| 507 |    613.270702 |    612.001998 | NA                                                                                                                                                                    |
| 508 |    928.592507 |    763.588517 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                                     |
| 509 |    687.413601 |    218.953985 | Emily Jane McTavish, from <http://chestofbooks.com/animals/Manual-Of-Zoology/images/I-Order-Ciliata-41.jpg>                                                           |
| 510 |    771.170556 |    645.740229 | Steven Traver                                                                                                                                                         |
| 511 |    390.391158 |    405.875597 | Steven Traver                                                                                                                                                         |
| 512 |    124.402143 |    252.050594 | Zimices                                                                                                                                                               |
| 513 |    719.636331 |    114.449314 | ArtFavor & annaleeblysse                                                                                                                                              |
| 514 |    536.797587 |    780.795900 | Andy Wilson                                                                                                                                                           |
| 515 |    664.483724 |    728.751940 | Lukasiniho                                                                                                                                                            |
| 516 |    160.206464 |    793.347457 | Collin Gross                                                                                                                                                          |
| 517 |    211.938480 |    276.754172 | Gareth Monger                                                                                                                                                         |
| 518 |    689.090495 |    177.501637 | Margot Michaud                                                                                                                                                        |
| 519 |    213.413762 |    682.320334 | T. Michael Keesey                                                                                                                                                     |
| 520 |    530.496818 |    120.717649 | Chase Brownstein                                                                                                                                                      |
| 521 |     23.540019 |    350.731323 | Zimices                                                                                                                                                               |
| 522 |    114.998586 |    402.941077 | Matt Crook                                                                                                                                                            |
| 523 |    682.202161 |    489.230487 | FunkMonk                                                                                                                                                              |
| 524 |    957.632792 |     12.926440 | Matt Crook                                                                                                                                                            |
| 525 |    251.809062 |    262.821306 | Jagged Fang Designs                                                                                                                                                   |
| 526 |    962.787019 |    245.858661 | Scott Hartman                                                                                                                                                         |
| 527 |    375.442774 |    172.425628 | Maija Karala                                                                                                                                                          |
| 528 |    408.017577 |    630.094826 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 529 |    898.104815 |    463.742543 | Bruno Maggia                                                                                                                                                          |
| 530 |    665.336840 |    534.336133 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 531 |     56.771812 |     84.680032 | Dean Schnabel                                                                                                                                                         |
| 532 |    148.803729 |    760.621408 | T. Michael Keesey                                                                                                                                                     |
| 533 |    684.802321 |    372.977938 | Beth Reinke                                                                                                                                                           |
| 534 |    419.450484 |    169.133763 | Scott Hartman                                                                                                                                                         |
| 535 |    421.760938 |    728.171149 | Scott Reid                                                                                                                                                            |
| 536 |    346.042195 |    510.171169 | Matt Crook                                                                                                                                                            |
| 537 |    415.721258 |    129.906919 | B. Duygu Özpolat                                                                                                                                                      |
| 538 |    193.267140 |    549.518349 | Smokeybjb                                                                                                                                                             |
| 539 |    913.224907 |    676.006014 | T. Michael Keesey                                                                                                                                                     |
| 540 |    743.483377 |    563.570470 | Gopal Murali                                                                                                                                                          |
| 541 |    999.174106 |    246.327403 | NA                                                                                                                                                                    |
| 542 |    284.570920 |    481.311316 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                                |
| 543 |    636.085918 |    536.439067 | Andy Wilson                                                                                                                                                           |
| 544 |    710.780806 |    665.994100 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                              |
| 545 |    251.030379 |     70.009110 | T. Tischler                                                                                                                                                           |
| 546 |    168.290761 |    669.883924 | Nobu Tamura                                                                                                                                                           |
| 547 |    979.517809 |    380.177097 | Matt Crook                                                                                                                                                            |
| 548 |    410.263653 |    652.801087 | Jagged Fang Designs                                                                                                                                                   |
| 549 |    283.719631 |     82.953075 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 550 |     78.048873 |    127.604254 | JCGiron                                                                                                                                                               |
| 551 |    414.657326 |     79.014211 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 552 |      9.855446 |    573.514109 | Courtney Rockenbach                                                                                                                                                   |
| 553 |    115.494679 |    589.857257 | Lafage                                                                                                                                                                |
| 554 |    848.677470 |    339.057669 | Mathew Stewart                                                                                                                                                        |
| 555 |    885.553623 |    183.091392 | C. Camilo Julián-Caballero                                                                                                                                            |
| 556 |    543.068007 |    407.359317 | Zimices                                                                                                                                                               |
| 557 |    267.284563 |    106.081684 | Zimices                                                                                                                                                               |
| 558 |    579.133699 |    512.430671 | Mette Aumala                                                                                                                                                          |
| 559 |    398.706847 |    468.562884 | T. Michael Keesey                                                                                                                                                     |
| 560 |    422.661834 |    244.488215 | Gareth Monger                                                                                                                                                         |
| 561 |    957.324265 |    658.724036 | Ignacio Contreras                                                                                                                                                     |
| 562 |    279.966421 |    684.518536 | Zimices                                                                                                                                                               |
| 563 |    517.305184 |     43.199878 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 564 |    479.666292 |    779.069450 | Matt Crook                                                                                                                                                            |
| 565 |    786.189508 |    460.367492 | T. Michael Keesey                                                                                                                                                     |
| 566 |    623.582910 |    395.079785 | Cathy                                                                                                                                                                 |
| 567 |    579.766362 |    127.884131 | Margot Michaud                                                                                                                                                        |
| 568 |    231.351088 |    648.460061 |                                                                                                                                                                       |
| 569 |     15.008160 |    756.062728 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                        |
| 570 |    358.096367 |    460.353603 | Zimices                                                                                                                                                               |
| 571 |    610.825011 |    358.537893 | Ludwik Gąsiorowski                                                                                                                                                    |
| 572 |    963.242290 |    374.693621 | Hugo Gruson                                                                                                                                                           |
| 573 |    444.401014 |    175.747709 | Scott Hartman                                                                                                                                                         |
| 574 |    987.156810 |    634.630619 | Margot Michaud                                                                                                                                                        |
| 575 |    733.851919 |    360.579626 | Margot Michaud                                                                                                                                                        |
| 576 |     63.956691 |     74.833238 | Nicolas Mongiardino Koch                                                                                                                                              |
| 577 |    183.124400 |     74.656226 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 578 |    164.082110 |    772.701202 | Rafael Maia                                                                                                                                                           |
| 579 |    136.545814 |    170.739919 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 580 |    984.306949 |    521.572118 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 581 |    829.264232 |    749.638929 | Smokeybjb                                                                                                                                                             |
| 582 |    748.280194 |    666.108535 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                              |
| 583 |    199.874714 |    646.677624 | Zimices                                                                                                                                                               |
| 584 |   1005.555801 |     16.203642 | Sharon Wegner-Larsen                                                                                                                                                  |
| 585 |    206.351742 |    145.501036 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                                 |
| 586 |    599.178744 |    453.362444 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 587 |    473.148579 |    300.076198 | NA                                                                                                                                                                    |
| 588 |    520.170512 |    668.682043 | Scott Hartman                                                                                                                                                         |
| 589 |    481.239453 |    113.811410 | Andy Wilson                                                                                                                                                           |
| 590 |   1010.566802 |    221.727886 | FunkMonk                                                                                                                                                              |
| 591 |    809.338021 |    341.504978 | Zimices                                                                                                                                                               |
| 592 |    951.301954 |    252.253240 | Scott Hartman                                                                                                                                                         |
| 593 |    710.098079 |     25.757762 | Andrew A. Farke                                                                                                                                                       |
| 594 |    437.426337 |    617.025229 | Matt Dempsey                                                                                                                                                          |
| 595 |    128.634561 |    264.731179 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 596 |    238.389004 |    205.863524 | Ghedo and T. Michael Keesey                                                                                                                                           |
| 597 |    384.489624 |    634.314646 | T. Michael Keesey                                                                                                                                                     |
| 598 |    739.139557 |    708.804582 | Steven Traver                                                                                                                                                         |
| 599 |    866.145175 |    366.050284 | NA                                                                                                                                                                    |
| 600 |    917.852364 |    748.706309 | Gareth Monger                                                                                                                                                         |
| 601 |    727.978133 |    632.085374 | Steven Traver                                                                                                                                                         |
| 602 |    477.895841 |    711.349917 | Scott Hartman                                                                                                                                                         |
| 603 |    138.826631 |    210.364417 | Kent Elson Sorgon                                                                                                                                                     |
| 604 |    556.830335 |    185.002202 | Chris huh                                                                                                                                                             |
| 605 |    806.950798 |    171.744569 | Frank Denota                                                                                                                                                          |
| 606 |   1016.895002 |    241.638647 | Mali’o Kodis, image by Rebecca Ritger                                                                                                                                 |
| 607 |    292.043130 |     60.355761 | T. Michael Keesey                                                                                                                                                     |
| 608 |    810.688143 |    707.970711 | Margot Michaud                                                                                                                                                        |
| 609 |   1013.107875 |    475.348916 | Scott Hartman                                                                                                                                                         |
| 610 |    528.441782 |    183.811975 | Andy Wilson                                                                                                                                                           |
| 611 |     10.373034 |    659.790262 | Xvazquez (vectorized by William Gearty)                                                                                                                               |
| 612 |    610.496375 |    138.281714 | Zimices                                                                                                                                                               |
| 613 |    318.022646 |    203.309635 | Noah Schlottman                                                                                                                                                       |
| 614 |    727.377874 |    717.587923 | Tasman Dixon                                                                                                                                                          |
| 615 |    230.271989 |     86.014632 | Steven Traver                                                                                                                                                         |
| 616 |     92.933195 |    338.734691 | Zimices                                                                                                                                                               |
| 617 |    169.374603 |     42.513074 | Mathew Wedel                                                                                                                                                          |
| 618 |    329.005507 |    453.267139 | E. J. Van Nieukerken, A. Laštůvka, and Z. Laštůvka (vectorized by T. Michael Keesey)                                                                                  |
| 619 |    429.847924 |    415.315578 | Tasman Dixon                                                                                                                                                          |
| 620 |    608.715576 |     21.692828 | Kai R. Caspar                                                                                                                                                         |
| 621 |    800.091898 |    401.662914 | Gareth Monger                                                                                                                                                         |
| 622 |    204.560281 |    349.614286 | Julie Blommaert based on photo by Sofdrakou                                                                                                                           |
| 623 |    146.929409 |    746.446412 | Chris huh                                                                                                                                                             |
| 624 |    140.173796 |    452.173478 | T. Michael Keesey                                                                                                                                                     |
| 625 |    636.354809 |    741.272991 | Kai R. Caspar                                                                                                                                                         |
| 626 |   1016.147682 |    265.831156 | T. Michael Keesey (vectorization) and Larry Loos (photography)                                                                                                        |
| 627 |    769.819403 |    240.018440 | Kamil S. Jaron                                                                                                                                                        |
| 628 |    211.431596 |    534.660870 | Ignacio Contreras                                                                                                                                                     |
| 629 |    648.145837 |    723.694832 | Zimices                                                                                                                                                               |
| 630 |    889.569857 |    379.671888 | Zimices                                                                                                                                                               |
| 631 |    389.862593 |    342.157242 | Ferran Sayol                                                                                                                                                          |
| 632 |    751.969215 |    320.824660 | L. Shyamal                                                                                                                                                            |
| 633 |    208.342038 |    477.908428 | FunkMonk                                                                                                                                                              |
| 634 |    285.108501 |    593.212348 | Armin Reindl                                                                                                                                                          |
| 635 |    856.919577 |    256.597285 | Matt Crook                                                                                                                                                            |
| 636 |    290.262062 |     26.414893 | Steven Traver                                                                                                                                                         |
| 637 |    325.136201 |    700.591353 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 638 |    636.329233 |    229.279414 | Iain Reid                                                                                                                                                             |
| 639 |    644.079282 |    649.659864 | Zimices                                                                                                                                                               |
| 640 |    912.455707 |    259.631902 | Scott Hartman                                                                                                                                                         |
| 641 |    296.464100 |    319.363177 | Joanna Wolfe                                                                                                                                                          |
| 642 |    524.213226 |    769.791438 | Margot Michaud                                                                                                                                                        |
| 643 |    166.596023 |    412.435820 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 644 |    333.825909 |    571.761936 | Jagged Fang Designs                                                                                                                                                   |
| 645 |    932.081526 |    469.263124 | Tasman Dixon                                                                                                                                                          |
| 646 |    636.754389 |    639.871257 | Elisabeth Östman                                                                                                                                                      |
| 647 |    373.419032 |    782.019431 | Beth Reinke                                                                                                                                                           |
| 648 |    403.089177 |    739.732146 | Margot Michaud                                                                                                                                                        |
| 649 |    937.209497 |    262.962837 | Ingo Braasch                                                                                                                                                          |
| 650 |    320.508891 |    331.911524 | Margot Michaud                                                                                                                                                        |
| 651 |    241.884365 |    512.246676 | NA                                                                                                                                                                    |
| 652 |    796.185375 |    693.361495 | Scott Hartman                                                                                                                                                         |
| 653 |    701.955436 |    132.200598 | NA                                                                                                                                                                    |
| 654 |    760.486948 |    167.619655 | T. Michael Keesey                                                                                                                                                     |
| 655 |    143.138279 |    250.040625 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 656 |     73.321498 |    320.999820 | Erika Schumacher                                                                                                                                                      |
| 657 |     14.635771 |    369.603371 | Chris huh                                                                                                                                                             |
| 658 |    478.819223 |    593.810969 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 659 |    463.025031 |    617.392930 | Steven Traver                                                                                                                                                         |
| 660 |    819.430584 |    184.113165 | Tasman Dixon                                                                                                                                                          |
| 661 |    582.470924 |    435.560792 | Birgit Lang                                                                                                                                                           |
| 662 |    388.945962 |     82.004899 | NA                                                                                                                                                                    |
| 663 |    624.097344 |    576.321022 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 664 |    506.720798 |    632.339536 | T. Tischler                                                                                                                                                           |
| 665 |    736.990198 |    371.742243 | Ignacio Contreras                                                                                                                                                     |
| 666 |    962.648317 |    787.310917 | Cagri Cevrim                                                                                                                                                          |
| 667 |    655.607876 |    117.036116 | Caio Bernardes, vectorized by Zimices                                                                                                                                 |
| 668 |    725.647196 |    452.488683 | Jagged Fang Designs                                                                                                                                                   |
| 669 |    945.346667 |    480.703961 | NA                                                                                                                                                                    |
| 670 |    128.639776 |    585.118086 | Scott Hartman                                                                                                                                                         |
| 671 |    689.686954 |    572.756071 | Jaime Headden                                                                                                                                                         |
| 672 |    234.807338 |    116.297714 | Steven Traver                                                                                                                                                         |
| 673 |    491.549993 |    166.540275 | Birgit Lang                                                                                                                                                           |
| 674 |    699.649888 |    169.080412 | Chris huh                                                                                                                                                             |
| 675 |    886.884997 |    100.191359 | Jaime Headden                                                                                                                                                         |
| 676 |    898.212041 |    447.106923 | NA                                                                                                                                                                    |
| 677 |    779.469362 |     97.474147 | mystica                                                                                                                                                               |
| 678 |    813.798594 |    299.366355 | NA                                                                                                                                                                    |
| 679 |    439.934993 |    156.260018 | Shyamal                                                                                                                                                               |
| 680 |     60.426710 |    113.180772 | Gareth Monger                                                                                                                                                         |
| 681 |    781.060353 |    705.640673 | Gareth Monger                                                                                                                                                         |
| 682 |    861.639062 |     76.092760 | Collin Gross                                                                                                                                                          |
| 683 |    887.804956 |      5.768260 | Xavier Giroux-Bougard                                                                                                                                                 |
| 684 |    826.676454 |    345.206244 | Scott Hartman                                                                                                                                                         |
| 685 |    133.076490 |    185.613383 | Jagged Fang Designs                                                                                                                                                   |
| 686 |    627.163630 |    745.271464 | Ferran Sayol                                                                                                                                                          |
| 687 |    873.154993 |    177.734168 | T. Michael Keesey                                                                                                                                                     |
| 688 |    104.988166 |    291.744212 | NA                                                                                                                                                                    |
| 689 |    824.785058 |    290.734802 | Ignacio Contreras                                                                                                                                                     |
| 690 |    310.788196 |    686.501238 | Aviceda (photo) & T. Michael Keesey                                                                                                                                   |
| 691 |    313.781683 |    494.912537 | Tyler Greenfield and Scott Hartman                                                                                                                                    |
| 692 |   1002.651983 |    603.180782 | Andrew A. Farke, modified from original by H. Milne Edwards                                                                                                           |
| 693 |    344.161227 |    773.040405 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 694 |    736.645506 |    168.648380 | Xavier Giroux-Bougard                                                                                                                                                 |
| 695 |    786.080047 |     80.039102 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 696 |    319.621559 |    735.168568 | Mette Aumala                                                                                                                                                          |
| 697 |    730.380434 |    690.601445 | NA                                                                                                                                                                    |
| 698 |    819.106261 |    455.482158 | Riccardo Percudani                                                                                                                                                    |
| 699 |    553.402662 |     48.874760 | Zimices                                                                                                                                                               |
| 700 |    753.108077 |    407.182695 | Alex Slavenko                                                                                                                                                         |
| 701 |     48.582733 |    321.184321 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                           |
| 702 |    508.131047 |    169.772061 | Ferran Sayol                                                                                                                                                          |
| 703 |    872.646034 |     22.191637 | L. Shyamal                                                                                                                                                            |
| 704 |    832.025508 |    551.029165 | Craig Dylke                                                                                                                                                           |
| 705 |   1002.047928 |    620.480725 | Tasman Dixon                                                                                                                                                          |
| 706 |    621.298898 |      3.661989 | Markus A. Grohme                                                                                                                                                      |
| 707 |    119.714959 |     38.843168 | Michael P. Taylor                                                                                                                                                     |
| 708 |    165.066417 |    426.351250 | Chris huh                                                                                                                                                             |
| 709 |    986.753108 |    303.385654 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 710 |    839.618928 |    712.535379 | Matt Crook                                                                                                                                                            |
| 711 |    228.587158 |    265.759157 | Zimices                                                                                                                                                               |
| 712 |     52.548453 |    282.609127 | Katie S. Collins                                                                                                                                                      |
| 713 |    584.033394 |    485.600565 | Birgit Lang                                                                                                                                                           |
| 714 |    266.380432 |    258.529129 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 715 |    987.076670 |    361.965364 | Andreas Preuss / marauder                                                                                                                                             |
| 716 |    417.934706 |    186.402142 | Zimices                                                                                                                                                               |
| 717 |    858.824449 |    278.148516 | Margot Michaud                                                                                                                                                        |
| 718 |    398.268424 |      4.642297 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 719 |    348.024535 |    434.584640 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 720 |    722.115058 |     75.925408 | Matt Crook                                                                                                                                                            |
| 721 |    925.903975 |    698.049105 | Sean McCann                                                                                                                                                           |
| 722 |    375.875417 |    747.399938 | Scott Hartman                                                                                                                                                         |
| 723 |    208.785044 |    786.056566 | NA                                                                                                                                                                    |
| 724 |     45.011062 |    591.743562 | NA                                                                                                                                                                    |
| 725 |    106.738657 |     21.356690 | Margot Michaud                                                                                                                                                        |
| 726 |    725.676405 |    290.793687 | Matt Crook                                                                                                                                                            |
| 727 |    733.890650 |    148.924148 | Chuanixn Yu                                                                                                                                                           |
| 728 |    135.654024 |    479.497748 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 729 |    408.674350 |     70.691970 | Kamil S. Jaron                                                                                                                                                        |
| 730 |    527.734044 |    134.120109 | Zimices                                                                                                                                                               |
| 731 |    136.279005 |    428.139306 | Rebecca Groom                                                                                                                                                         |
| 732 |    386.195207 |    145.957703 | Sarah Werning                                                                                                                                                         |
| 733 |    711.199732 |    373.709332 | NASA                                                                                                                                                                  |
| 734 |    597.414407 |    356.462751 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 735 |    511.131754 |    315.355666 | xgirouxb                                                                                                                                                              |
| 736 |    770.044043 |    651.640722 | Julio Garza                                                                                                                                                           |
| 737 |    998.627495 |    343.824339 | Beth Reinke                                                                                                                                                           |
| 738 |    938.795966 |    160.096358 | Bob Goldstein, Vectorization:Jake Warner                                                                                                                              |
| 739 |    119.924914 |    431.454817 | Andy Wilson                                                                                                                                                           |
| 740 |    153.643038 |    455.208794 | NA                                                                                                                                                                    |
| 741 |    622.674856 |    713.316413 | Roberto Díaz Sibaja                                                                                                                                                   |
| 742 |     64.324721 |     94.414889 | Chris huh                                                                                                                                                             |
| 743 |    622.792578 |    774.077486 | Armin Reindl                                                                                                                                                          |
| 744 |    784.381733 |    721.660769 | Margot Michaud                                                                                                                                                        |
| 745 |    344.671155 |    234.119008 | Riccardo Percudani                                                                                                                                                    |
| 746 |    667.316001 |     45.620376 | Chase Brownstein                                                                                                                                                      |
| 747 |    175.408724 |    385.785114 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 748 |    101.888015 |    636.489545 | Zimices                                                                                                                                                               |
| 749 |    582.916880 |    285.573535 | Rene Martin                                                                                                                                                           |
| 750 |    234.239256 |    670.507197 | Scott Hartman                                                                                                                                                         |
| 751 |    692.546461 |    466.059992 | Steven Traver                                                                                                                                                         |
| 752 |    698.624935 |     23.364853 | Margot Michaud                                                                                                                                                        |
| 753 |    274.105745 |      8.500761 | Matt Crook                                                                                                                                                            |
| 754 |    478.220751 |    468.619676 | NA                                                                                                                                                                    |
| 755 |    359.541487 |    602.683464 | Armin Reindl                                                                                                                                                          |
| 756 |    819.668109 |    441.734045 | Ricardo Araújo                                                                                                                                                        |
| 757 |     50.392269 |    691.816769 | Dr. Thomas G. Barnes, USFWS                                                                                                                                           |
| 758 |    498.070482 |    400.471558 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 759 |   1016.087349 |    482.530605 | Steven Traver                                                                                                                                                         |
| 760 |    147.305501 |    281.769046 | Zimices                                                                                                                                                               |
| 761 |    672.506887 |    764.804867 | Zimices                                                                                                                                                               |
| 762 |    299.549360 |    762.612532 | Jagged Fang Designs                                                                                                                                                   |
| 763 |    550.240333 |    442.257574 | Ferran Sayol                                                                                                                                                          |
| 764 |    206.526643 |    133.504780 | CNZdenek                                                                                                                                                              |
| 765 |    988.340123 |    331.875306 | Campbell Fleming                                                                                                                                                      |
| 766 |    231.037338 |    172.510959 | Riccardo Percudani                                                                                                                                                    |
| 767 |    975.221243 |    281.199287 | Sarah Werning                                                                                                                                                         |
| 768 |    423.190024 |    717.038653 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                                  |
| 769 |    490.855120 |    164.246255 | Andy Wilson                                                                                                                                                           |
| 770 |    675.302370 |    451.279709 | Tauana J. Cunha                                                                                                                                                       |
| 771 |     30.156568 |    214.698182 | Zimices                                                                                                                                                               |
| 772 |    402.729929 |    352.996853 | Matt Crook                                                                                                                                                            |
| 773 |    711.427283 |    553.021959 | Noah Schlottman                                                                                                                                                       |
| 774 |    513.334322 |    325.418717 | Matt Crook                                                                                                                                                            |
| 775 |    560.990947 |     63.547861 | Matt Crook                                                                                                                                                            |
| 776 |    958.120264 |    153.509129 | Markus A. Grohme                                                                                                                                                      |
| 777 |    592.366809 |     35.433620 | T. Michael Keesey                                                                                                                                                     |
| 778 |    379.412762 |    351.077390 | Dean Schnabel                                                                                                                                                         |
| 779 |     52.367373 |    720.843350 | Dean Schnabel                                                                                                                                                         |
| 780 |   1013.502237 |    740.651408 | Gareth Monger                                                                                                                                                         |
| 781 |    650.325389 |    524.688144 | Chris huh                                                                                                                                                             |
| 782 |    269.803155 |    792.134818 | T. Michael Keesey (after Heinrich Harder)                                                                                                                             |
| 783 |    566.040516 |    289.594525 | T. Michael Keesey                                                                                                                                                     |
| 784 |    264.361707 |    406.216633 | Anthony Caravaggi                                                                                                                                                     |
| 785 |    416.524967 |    542.239728 | Katie S. Collins                                                                                                                                                      |
| 786 |    776.941818 |    256.829254 | Jack Mayer Wood                                                                                                                                                       |
| 787 |    546.914510 |    665.301499 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 788 |    728.020088 |    221.215516 | Dean Schnabel                                                                                                                                                         |
| 789 |    307.028950 |    264.222700 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 790 |    631.943344 |     54.032556 | Aleksey Nagovitsyn (vectorized by T. Michael Keesey)                                                                                                                  |
| 791 |    801.557793 |    758.932567 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 792 |    296.280995 |    354.526055 | Louis Ranjard                                                                                                                                                         |
| 793 |    250.499982 |    236.199868 | Mathew Wedel                                                                                                                                                          |
| 794 |    222.733073 |    326.256737 | mystica                                                                                                                                                               |
| 795 |    989.754592 |    282.468098 | Caleb M. Brown                                                                                                                                                        |
| 796 |    817.421277 |    513.041554 | Joanna Wolfe                                                                                                                                                          |
| 797 |    513.206755 |    773.254232 | Roberto Díaz Sibaja                                                                                                                                                   |
| 798 |    627.752193 |    724.223033 | Lukasiniho                                                                                                                                                            |
| 799 |    433.019923 |    674.468682 | Ferran Sayol                                                                                                                                                          |
| 800 |    130.969748 |    596.417513 | Jagged Fang Designs                                                                                                                                                   |
| 801 |    152.347390 |    687.063809 | Katie S. Collins                                                                                                                                                      |
| 802 |    822.116360 |    257.818534 | Michael P. Taylor                                                                                                                                                     |
| 803 |    713.582418 |    418.497539 | Matt Crook                                                                                                                                                            |
| 804 |    594.318929 |    179.782773 | Dean Schnabel                                                                                                                                                         |
| 805 |     90.920654 |    612.473907 | C. Camilo Julián-Caballero                                                                                                                                            |
| 806 |    414.216338 |    263.823456 | Lindberg (vectorized by T. Michael Keesey)                                                                                                                            |
| 807 |    832.175943 |    498.826305 | Cesar Julian                                                                                                                                                          |
| 808 |    971.166183 |    127.590204 | Zimices                                                                                                                                                               |
| 809 |     32.928814 |    508.551826 | Markus A. Grohme                                                                                                                                                      |
| 810 |    840.896881 |     38.708237 | Trond R. Oskars                                                                                                                                                       |
| 811 |    764.481784 |     34.691631 | Andy Wilson                                                                                                                                                           |
| 812 |    470.339502 |    790.513536 | Tasman Dixon                                                                                                                                                          |
| 813 |    700.420666 |     39.819144 | FunkMonk                                                                                                                                                              |
| 814 |    186.741520 |     58.549675 | Karina Garcia                                                                                                                                                         |
| 815 |    155.581391 |    597.930078 | Margot Michaud                                                                                                                                                        |
| 816 |    188.501818 |    252.232485 | Dean Schnabel                                                                                                                                                         |
| 817 |     59.245239 |     60.433320 | Andy Wilson                                                                                                                                                           |
| 818 |    397.725270 |    535.096379 | T. Michael Keesey                                                                                                                                                     |
| 819 |    975.561006 |    143.546317 | Melissa Broussard                                                                                                                                                     |
| 820 |    738.769645 |     81.857860 | Margot Michaud                                                                                                                                                        |
| 821 |    398.859525 |    118.263201 | Owen Jones (derived from a CC-BY 2.0 photograph by Paulo B. Chaves)                                                                                                   |
| 822 |   1000.821958 |    570.305237 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 823 |    975.175375 |    422.126341 | Mali’o Kodis, image from the “Proceedings of the Zoological Society of London”                                                                                        |
| 824 |    849.331258 |    326.476242 | Birgit Lang                                                                                                                                                           |
| 825 |     25.521155 |    466.244753 | Jagged Fang Designs                                                                                                                                                   |
| 826 |    522.533231 |    100.888653 | Xavier Giroux-Bougard                                                                                                                                                 |
| 827 |    109.471574 |    279.783167 | Margot Michaud                                                                                                                                                        |
| 828 |    979.358678 |    661.654811 | Gareth Monger                                                                                                                                                         |
| 829 |    138.832178 |    575.265899 | Sean McCann                                                                                                                                                           |
| 830 |    660.850977 |    169.953338 | Beth Reinke                                                                                                                                                           |
| 831 |    915.302903 |    455.536358 | Anthony Caravaggi                                                                                                                                                     |
| 832 |    691.041826 |    240.262181 | Collin Gross                                                                                                                                                          |
| 833 |    544.453777 |    694.513003 | Gareth Monger                                                                                                                                                         |
| 834 |   1003.917090 |    213.228702 | M. A. Broussard                                                                                                                                                       |
| 835 |    488.598113 |     35.551608 | Tasman Dixon                                                                                                                                                          |
| 836 |    563.517192 |    491.252690 | Michael Scroggie                                                                                                                                                      |
| 837 |    666.794882 |    671.712795 | Mattia Menchetti                                                                                                                                                      |
| 838 |    983.037454 |     14.319466 | Steven Traver                                                                                                                                                         |
| 839 |    661.366484 |    684.709357 | Matt Crook                                                                                                                                                            |
| 840 |    970.060267 |    693.734165 | Matt Crook                                                                                                                                                            |
| 841 |    709.134903 |    505.131018 | Margot Michaud                                                                                                                                                        |
| 842 |    385.530891 |    503.062899 | CNZdenek                                                                                                                                                              |
| 843 |     14.165903 |    271.031347 | Matt Crook                                                                                                                                                            |
| 844 |    453.459888 |    795.694975 | Agnello Picorelli                                                                                                                                                     |
| 845 |     68.916759 |    788.653792 | Roberto Díaz Sibaja                                                                                                                                                   |
| 846 |    810.147489 |    714.357424 | Steven Coombs                                                                                                                                                         |
| 847 |    870.695870 |    710.438822 | Zimices                                                                                                                                                               |
| 848 |    823.519277 |    332.094428 | Walter Vladimir                                                                                                                                                       |
| 849 |    151.925435 |    572.641552 | Zimices                                                                                                                                                               |
| 850 |    262.678088 |    676.782109 | Inessa Voet                                                                                                                                                           |
| 851 |    369.453075 |    462.159551 | Erika Schumacher                                                                                                                                                      |
| 852 |    591.592418 |    793.400299 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 853 |     34.131726 |    488.971064 | Michelle Site                                                                                                                                                         |
| 854 |    285.896821 |    172.197298 | NA                                                                                                                                                                    |
| 855 |    475.860184 |    341.251199 | Gareth Monger                                                                                                                                                         |
| 856 |    827.237617 |     41.757574 | Gareth Monger                                                                                                                                                         |
| 857 |    435.982152 |    114.936494 | Gareth Monger                                                                                                                                                         |
| 858 |      8.973835 |    584.384914 | Melissa Broussard                                                                                                                                                     |
| 859 |    284.715358 |    148.101372 | Robert Gay, modifed from Olegivvit                                                                                                                                    |
| 860 |    664.061362 |     81.321670 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 861 |    230.080165 |    132.403920 | Jagged Fang Designs                                                                                                                                                   |
| 862 |    881.569259 |    766.688266 | NA                                                                                                                                                                    |
| 863 |    740.333639 |    715.785042 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 864 |    734.615294 |    791.263183 | NA                                                                                                                                                                    |
| 865 |    968.341233 |    678.892830 | NA                                                                                                                                                                    |
| 866 |    637.603718 |    620.900524 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                            |
| 867 |    248.030614 |    170.818945 | Yan Wong                                                                                                                                                              |
| 868 |    797.137393 |    708.173489 | Steven Traver                                                                                                                                                         |
| 869 |    254.477727 |    496.388594 | Margot Michaud                                                                                                                                                        |
| 870 |    909.752297 |    152.574851 | Iain Reid                                                                                                                                                             |
| 871 |    967.408218 |    519.038617 | Ferran Sayol                                                                                                                                                          |
| 872 |    466.704149 |    274.864818 | xgirouxb                                                                                                                                                              |
| 873 |    465.510194 |     13.570304 | NA                                                                                                                                                                    |
| 874 |    857.413472 |     62.915355 | Renato Santos                                                                                                                                                         |
| 875 |    738.642771 |    621.977387 | Margot Michaud                                                                                                                                                        |
| 876 |    160.108637 |    676.201785 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 877 |    624.817382 |    696.781519 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                         |
| 878 |    582.015421 |    164.549273 | Steven Traver                                                                                                                                                         |
| 879 |    236.045733 |    399.769810 | T. Michael Keesey                                                                                                                                                     |
| 880 |    440.672034 |    269.294565 | T. Michael Keesey                                                                                                                                                     |
| 881 |    837.615079 |    309.102622 | L. Shyamal                                                                                                                                                            |
| 882 |    185.586654 |    538.969512 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 883 |    585.074348 |      7.865350 | Erika Schumacher                                                                                                                                                      |
| 884 |    467.091919 |    264.455044 | Margot Michaud                                                                                                                                                        |
| 885 |    587.458457 |    629.892113 | Zimices                                                                                                                                                               |
| 886 |    228.221968 |    482.331891 | Michelle Site                                                                                                                                                         |
| 887 |    752.635420 |     40.343853 | Joedison Rocha                                                                                                                                                        |
| 888 |    354.126267 |    217.110541 | Alexander Schmidt-Lebuhn                                                                                                                                              |
| 889 |    651.360301 |    789.061762 | Birgit Lang                                                                                                                                                           |
| 890 |    755.468116 |    570.708063 | Chuanixn Yu                                                                                                                                                           |
| 891 |    611.496119 |     43.599400 | Kanchi Nanjo                                                                                                                                                          |
| 892 |   1005.474627 |    790.836416 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                          |
| 893 |    752.527058 |    624.207333 | Gareth Monger                                                                                                                                                         |
| 894 |     42.013246 |    668.729386 | Steven Traver                                                                                                                                                         |
| 895 |   1007.331673 |    692.412543 | Gareth Monger                                                                                                                                                         |
| 896 |    155.279277 |    133.757663 | Pollyanna von Knorring and T. Michael Keesey                                                                                                                          |
| 897 |    782.187797 |    166.435432 | Margot Michaud                                                                                                                                                        |
| 898 |    827.077323 |    379.103802 | Emily Willoughby                                                                                                                                                      |
| 899 |    991.604127 |    486.359475 | Ingo Braasch                                                                                                                                                          |
| 900 |    954.654856 |    668.181787 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 901 |    122.625355 |    286.616927 | Christoph Schomburg                                                                                                                                                   |
| 902 |     20.014878 |    713.952959 | Sarah Werning                                                                                                                                                         |
| 903 |    319.795575 |    374.228405 | Ferran Sayol                                                                                                                                                          |
| 904 |     86.457797 |    143.342509 | NA                                                                                                                                                                    |
| 905 |    260.664316 |    120.523072 | Joanna Wolfe                                                                                                                                                          |
| 906 |    426.724451 |    571.496154 | Michelle Site                                                                                                                                                         |
| 907 |    961.752650 |    393.910609 | Terpsichores                                                                                                                                                          |
| 908 |    410.767954 |    766.514451 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 909 |   1008.811884 |    264.562792 | Gareth Monger                                                                                                                                                         |
| 910 |    782.298199 |    244.273275 | Margot Michaud                                                                                                                                                        |
| 911 |    238.565457 |    796.199486 | Bennet McComish, photo by Hans Hillewaert                                                                                                                             |
| 912 |    276.955231 |     25.973219 | Armin Reindl                                                                                                                                                          |
| 913 |    802.570775 |    506.559144 | Steven Traver                                                                                                                                                         |
| 914 |    530.147057 |    115.478674 | Jagged Fang Designs                                                                                                                                                   |
| 915 |    458.451894 |    161.053720 | Kevin Sánchez                                                                                                                                                         |
| 916 |    781.077705 |    665.516405 | Jaime Headden                                                                                                                                                         |
| 917 |    707.478406 |     15.608320 | Steven Traver                                                                                                                                                         |
| 918 |    869.643122 |     43.278912 | Matt Crook                                                                                                                                                            |
| 919 |    224.290109 |     66.165571 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 920 |    339.491710 |    700.946051 | Markus A. Grohme                                                                                                                                                      |

    #> Your tweet has been posted!
