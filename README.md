
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

Charles R. Knight, vectorized by Zimices, Matt Crook, Emily Willoughby,
Sergio A. Muñoz-Gómez, Zimices, Margot Michaud, Gareth Monger, Jaime
Headden, Markus A. Grohme, Josefine Bohr Brask, S.Martini, Ferran Sayol,
Felix Vaux, Gabriela Palomo-Munoz, Kai R. Caspar, Stanton F. Fink
(vectorized by T. Michael Keesey), Birgit Lang, Steven Traver, Beth
Reinke, Chris huh, Mathilde Cordellier, Andrew A. Farke, Jack Mayer
Wood, Tasman Dixon, Carlos Cano-Barbacil, Katie S. Collins, CNZdenek,
Brad McFeeters (vectorized by T. Michael Keesey), Jagged Fang Designs,
Didier Descouens (vectorized by T. Michael Keesey), Andrew A. Farke,
shell lines added by Yan Wong, Scott Hartman, Geoff Shaw, Benjamint444,
xgirouxb, Ricardo N. Martinez & Oscar A. Alcober, Tauana J. Cunha,
Campbell Fleming, Michelle Site, Lukasiniho, Chase Brownstein, Dean
Schnabel, Cesar Julian, Pranav Iyer (grey ideas), E. D. Cope (modified
by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel), Yan Wong
from wikipedia drawing (PD: Pearson Scott Foresman), Frank Denota, T.
Michael Keesey, Scott Hartman (modified by T. Michael Keesey), Milton
Tan, Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow
(vectorized by T. Michael Keesey), Ignacio Contreras, Nobu Tamura,
vectorized by Zimices, Kamil S. Jaron, C. Camilo Julián-Caballero,
Cathy, E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey), Andy
Wilson, Nobu Tamura (vectorized by A. Verrière), Fritz Geller-Grimm
(vectorized by T. Michael Keesey), Melissa Broussard, Dmitry Bogdanov
(vectorized by T. Michael Keesey), Johan Lindgren, Michael W. Caldwell,
Takuya Konishi, Luis M. Chiappe, Lukas Panzarin, Christoph Schomburg,
Nobu Tamura, Ellen Edmonson and Hugh Chrisp (illustration) and Timothy
J. Bartley (silhouette), Bennet McComish, photo by Avenue, Mathieu
Pélissié, Lafage, Maija Karala, Tracy A. Heath, Jebulon (vectorized by
T. Michael Keesey), Matt Dempsey, Dmitry Bogdanov, vectorized by
Zimices, Agnello Picorelli, FunkMonk, Taenadoman, Robert Gay, modifed
from Olegivvit, AnAgnosticGod (vectorized by T. Michael Keesey),
Auckland Museum, Terpsichores, Karkemish (vectorized by T. Michael
Keesey), Alexandre Vong, Pete Buchholz, Scott D. Sampson, Mark A.
Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua
A. Smith, Alan L. Titus, Steven Coombs, Natasha Vitek, Lee Harding
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, NASA, Prin Pattawaro (photo), John E. McCormack, Michael G.
Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb
T. Brumfield & T. Michael Keesey, JCGiron, Nobu Tamura (vectorized by T.
Michael Keesey), DW Bapst, modified from Ishitani et al. 2016, wsnaccad,
Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist,
Collin Gross, Shyamal, Anna Willoughby, Alexander Schmidt-Lebuhn, Walter
Vladimir, Iain Reid, Mali’o Kodis, image from the Smithsonian
Institution, Erika Schumacher, Armin Reindl, Ray Simpson (vectorized by
T. Michael Keesey), Pearson Scott Foresman (vectorized by T. Michael
Keesey), Michael Scroggie, J. J. Harrison (photo) & T. Michael Keesey,
Sarah Werning, Crystal Maier, Paul Baker (photo), John E. McCormack,
Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C.
Glenn, Robb T. Brumfield & T. Michael Keesey, Julio Garza, Matt
Martyniuk, Danielle Alba, A. H. Baldwin (vectorized by T. Michael
Keesey), Keith Murdock (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Inessa Voet, Unknown (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, L. Shyamal,
Martin R. Smith, after Skovsted et al 2015, Blair Perry, Robbie N. Cada
(vectorized by T. Michael Keesey), Christine Axon, Francesco
“Architetto” Rollandin, Robert Gay, Tom Tarrant (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Ieuan Jones,
Dantheman9758 (vectorized by T. Michael Keesey), (after Spotila 2004),
Rebecca Groom, Cristopher Silva, kreidefossilien.de, Almandine
(vectorized by T. Michael Keesey), Smokeybjb (modified by T. Michael
Keesey), CDC (Alissa Eckert; Dan Higgins), Darren Naish (vectorize by T.
Michael Keesey), Metalhead64 (vectorized by T. Michael Keesey), , James
R. Spotila and Ray Chatterji, Noah Schlottman, photo by Casey Dunn,
Francisco Gascó (modified by Michael P. Taylor), Mathew Wedel, Noah
Schlottman, photo by Hans De Blauwe, Birgit Lang, based on a photo by D.
Sikes, Alexis Simon, Konsta Happonen, Maxime Dahirel, Caleb M. Brown,
Kristina Gagalova, Zachary Quigley, Mattia Menchetti, Apokryltaros
(vectorized by T. Michael Keesey), Smokeybjb, Yusan Yang, Jose Carlos
Arenas-Monroy, FunkMonk (Michael B.H.; vectorized by T. Michael Keesey),
Kailah Thorn & Ben King, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Jerry
Oldenettel (vectorized by T. Michael Keesey), Jessica Anne Miller, Mihai
Dragos (vectorized by T. Michael Keesey), Tyler Greenfield, Yan Wong,
Ghedo and T. Michael Keesey, B. Duygu Özpolat, Hans Hillewaert
(vectorized by T. Michael Keesey), David Tana, Xavier Giroux-Bougard,
Sharon Wegner-Larsen, Roberto Díaz Sibaja, Sean McCann, Michael P.
Taylor, Mark Miller, Raven Amos, Ingo Braasch, Stuart Humphries, Tony
Ayling (vectorized by T. Michael Keesey), Mark Hofstetter (vectorized by
T. Michael Keesey), T. Michael Keesey (after Kukalová), Chloé Schmidt,
Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime
Dahirel), Sarah Alewijnse, Jimmy Bernot, Skye McDavid, Ernst Haeckel
(vectorized by T. Michael Keesey), J Levin W (illustration) and T.
Michael Keesey (vectorization), Chuanixn Yu, Martin R. Smith, Richard
Parker (vectorized by T. Michael Keesey), John Gould (vectorized by T.
Michael Keesey), Oren Peles / vectorized by Yan Wong, FJDegrange, Kent
Elson Sorgon, Cristian Osorio & Paula Carrera, Proyecto Carnivoros
Australes (www.carnivorosaustrales.org), Chris Hay, David Orr, Arthur S.
Brum, Alyssa Bell & Luis Chiappe 2015,
dx.doi.org/10.1371/journal.pone.0141690, Mette Aumala, Benjamin
Monod-Broca, Harold N Eyster, Scott Reid, Mathieu Basille, Michael
“FunkMonk” B. H. (vectorized by T. Michael Keesey), Elizabeth Parker,
Matthew E. Clapham, Emily Jane McTavish, from
<http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>, Neil
Kelley, Estelle Bourdon, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Bruno C.
Vellutini, Davidson Sodré, Anthony Caravaggi, Bill Bouton (source photo)
& T. Michael Keesey (vectorization), Joe Schneid (vectorized by T.
Michael Keesey), Obsidian Soul (vectorized by T. Michael Keesey), Matt
Wilkins, Trond R. Oskars, Joris van der Ham (vectorized by T. Michael
Keesey), Gopal Murali, Konsta Happonen, from a CC-BY-NC image by
pelhonen on iNaturalist, Mason McNair, Noah Schlottman, photo by Antonio
Guillén, Matus Valach, Cagri Cevrim, Joanna Wolfe, Ville-Veikko
Sinkkonen, Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz
Sibaja, Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael
Keesey., Andrés Sánchez, Nobu Tamura (modified by T. Michael Keesey),
Alex Slavenko, Ghedoghedo (vectorized by T. Michael Keesey), Eduard Solà
Vázquez, vectorised by Yan Wong, Mali’o Kodis, photograph by Aqua-Photos
(<http://www.flickr.com/people/undervannsfotografen/>), Mali’o Kodis,
photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>),
Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Mo
Hassan, Wynston Cooper (photo) and Albertonykus (silhouette), Maky
(vectorization), Gabriella Skollar (photography), Rebecca Lewis
(editing), Fcb981 (vectorized by T. Michael Keesey), Burton Robert,
USFWS, Conty (vectorized by T. Michael Keesey), Manabu Sakamoto, Rene
Martin, LeonardoG (photography) and T. Michael Keesey (vectorization),
Skye M, Filip em, Vanessa Guerra, Jake Warner, Sam Droege (photo) and T.
Michael Keesey (vectorization), DW Bapst (modified from Mitchell 1990),
Ewald Rübsamen, Kevin Sánchez, Mali’o Kodis, photograph by Jim Vargo,
Fernando Carezzano, Robert Hering, Young and Zhao (1972:figure 4),
modified by Michael P. Taylor, V. Deepak, Dori <dori@merr.info> (source
photo) and Nevit Dilmen, Noah Schlottman, photo from National Science
Foundation - Turbellarian Taxonomic Database, Claus Rebler, Smokeybjb,
vectorized by Zimices

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                         |
| --: | ------------: | ------------: | :------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    565.370505 |    253.894335 | Charles R. Knight, vectorized by Zimices                                                                                                                       |
|   2 |    735.457188 |    681.631152 | Matt Crook                                                                                                                                                     |
|   3 |    111.837004 |    462.125057 | Emily Willoughby                                                                                                                                               |
|   4 |    632.103941 |    128.849571 | Sergio A. Muñoz-Gómez                                                                                                                                          |
|   5 |    130.013001 |     49.386295 | Zimices                                                                                                                                                        |
|   6 |    214.370381 |    660.208246 | Margot Michaud                                                                                                                                                 |
|   7 |    616.221748 |    457.241600 | Gareth Monger                                                                                                                                                  |
|   8 |    603.320187 |    623.922792 | NA                                                                                                                                                             |
|   9 |    262.381938 |    497.058568 | Jaime Headden                                                                                                                                                  |
|  10 |    261.406144 |    612.653885 | Markus A. Grohme                                                                                                                                               |
|  11 |     93.190035 |    304.082634 | Josefine Bohr Brask                                                                                                                                            |
|  12 |    449.664124 |    704.864169 | S.Martini                                                                                                                                                      |
|  13 |    636.157342 |    388.804965 | Zimices                                                                                                                                                        |
|  14 |    282.039943 |    245.717653 | Ferran Sayol                                                                                                                                                   |
|  15 |    486.363146 |    197.655732 | Felix Vaux                                                                                                                                                     |
|  16 |    943.695655 |    460.449167 | Gabriela Palomo-Munoz                                                                                                                                          |
|  17 |    852.045525 |    332.474198 | Kai R. Caspar                                                                                                                                                  |
|  18 |    389.371996 |    527.084257 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
|  19 |    302.769414 |    368.760939 | Birgit Lang                                                                                                                                                    |
|  20 |    660.221260 |    542.308229 | Ferran Sayol                                                                                                                                                   |
|  21 |    944.581817 |    200.746564 | Steven Traver                                                                                                                                                  |
|  22 |     79.853830 |    594.168846 | Ferran Sayol                                                                                                                                                   |
|  23 |    833.234235 |    223.416338 | Beth Reinke                                                                                                                                                    |
|  24 |    319.035615 |    121.766215 | Chris huh                                                                                                                                                      |
|  25 |    670.597885 |    268.471006 | Mathilde Cordellier                                                                                                                                            |
|  26 |    534.888962 |    768.232670 | Andrew A. Farke                                                                                                                                                |
|  27 |    820.749064 |     31.377828 | Jack Mayer Wood                                                                                                                                                |
|  28 |    463.967577 |    604.555463 | Tasman Dixon                                                                                                                                                   |
|  29 |    504.903650 |     79.828712 | Carlos Cano-Barbacil                                                                                                                                           |
|  30 |    367.691394 |    236.439646 | Katie S. Collins                                                                                                                                               |
|  31 |    314.106663 |     67.960806 | CNZdenek                                                                                                                                                       |
|  32 |    873.179882 |    527.253944 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
|  33 |    403.290495 |    348.538202 | Jagged Fang Designs                                                                                                                                            |
|  34 |    790.622547 |    433.395085 | Margot Michaud                                                                                                                                                 |
|  35 |    421.803812 |    405.274561 | Steven Traver                                                                                                                                                  |
|  36 |    928.863878 |    672.138106 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
|  37 |    962.736868 |    397.782987 | Andrew A. Farke, shell lines added by Yan Wong                                                                                                                 |
|  38 |    921.888541 |     89.689631 | Margot Michaud                                                                                                                                                 |
|  39 |    865.677874 |    277.044714 | Scott Hartman                                                                                                                                                  |
|  40 |    191.109194 |    393.104617 | Gabriela Palomo-Munoz                                                                                                                                          |
|  41 |    586.056665 |    482.653154 | Geoff Shaw                                                                                                                                                     |
|  42 |    543.828242 |    534.007087 | NA                                                                                                                                                             |
|  43 |    612.277666 |    720.151939 | Birgit Lang                                                                                                                                                    |
|  44 |    228.563654 |    750.033994 | Margot Michaud                                                                                                                                                 |
|  45 |    129.820203 |    188.076360 | Benjamint444                                                                                                                                                   |
|  46 |    379.064903 |    627.214365 | xgirouxb                                                                                                                                                       |
|  47 |    718.058820 |    363.070851 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                         |
|  48 |    820.678065 |    162.690448 | Tauana J. Cunha                                                                                                                                                |
|  49 |    906.204558 |    737.110360 | Steven Traver                                                                                                                                                  |
|  50 |    754.119357 |    118.165719 | Gareth Monger                                                                                                                                                  |
|  51 |    426.909392 |     40.230444 | Jagged Fang Designs                                                                                                                                            |
|  52 |     41.170109 |    406.603414 | Campbell Fleming                                                                                                                                               |
|  53 |     68.466873 |    711.477387 | Michelle Site                                                                                                                                                  |
|  54 |    204.762350 |    289.594145 | Lukasiniho                                                                                                                                                     |
|  55 |     80.817579 |    130.477228 | Chase Brownstein                                                                                                                                               |
|  56 |    900.598842 |    599.520195 | Michelle Site                                                                                                                                                  |
|  57 |    568.210580 |    335.536682 | Markus A. Grohme                                                                                                                                               |
|  58 |    711.646213 |    165.069957 | Dean Schnabel                                                                                                                                                  |
|  59 |    682.449772 |     27.597677 | Cesar Julian                                                                                                                                                   |
|  60 |    382.214181 |    302.071833 | Markus A. Grohme                                                                                                                                               |
|  61 |    339.878681 |    752.875524 | Emily Willoughby                                                                                                                                               |
|  62 |     92.063662 |    744.921158 | Matt Crook                                                                                                                                                     |
|  63 |    963.547227 |    311.594372 | NA                                                                                                                                                             |
|  64 |    775.875051 |    490.820342 | Steven Traver                                                                                                                                                  |
|  65 |    437.219008 |    458.655810 | Pranav Iyer (grey ideas)                                                                                                                                       |
|  66 |     67.535708 |    245.195440 | Scott Hartman                                                                                                                                                  |
|  67 |    317.419646 |    169.339015 | Gareth Monger                                                                                                                                                  |
|  68 |    411.884442 |    771.685903 | E. D. Cope (modified by T. Michael Keesey, Michael P. Taylor & Matthew J. Wedel)                                                                               |
|  69 |    607.271836 |     52.068005 | Yan Wong from wikipedia drawing (PD: Pearson Scott Foresman)                                                                                                   |
|  70 |    166.701414 |    558.878947 | Jagged Fang Designs                                                                                                                                            |
|  71 |    203.085129 |    551.375887 | Frank Denota                                                                                                                                                   |
|  72 |    484.251549 |    300.040195 | Zimices                                                                                                                                                        |
|  73 |    189.230095 |    152.593695 | T. Michael Keesey                                                                                                                                              |
|  74 |    233.173439 |     30.385671 | Scott Hartman (modified by T. Michael Keesey)                                                                                                                  |
|  75 |    334.846950 |    677.765715 | Margot Michaud                                                                                                                                                 |
|  76 |    956.969316 |    555.910010 | Markus A. Grohme                                                                                                                                               |
|  77 |    633.903805 |    195.554003 | Tasman Dixon                                                                                                                                                   |
|  78 |     29.185813 |    496.546744 | T. Michael Keesey                                                                                                                                              |
|  79 |    545.588446 |     18.268391 | Milton Tan                                                                                                                                                     |
|  80 |    764.622396 |    287.461667 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
|  81 |     89.752201 |    336.591364 | Ignacio Contreras                                                                                                                                              |
|  82 |    499.785585 |    141.625014 | Pranav Iyer (grey ideas)                                                                                                                                       |
|  83 |    913.264967 |     29.686197 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
|  84 |    308.836441 |    453.190536 | Chris huh                                                                                                                                                      |
|  85 |     25.445708 |    624.812032 | Gareth Monger                                                                                                                                                  |
|  86 |    326.907611 |    648.291504 | NA                                                                                                                                                             |
|  87 |   1008.446512 |    643.085831 | Gareth Monger                                                                                                                                                  |
|  88 |    227.542770 |     85.317033 | Markus A. Grohme                                                                                                                                               |
|  89 |    552.251175 |    710.356558 | Steven Traver                                                                                                                                                  |
|  90 |    638.655060 |    581.006063 | Kamil S. Jaron                                                                                                                                                 |
|  91 |    720.031150 |    393.689726 | Ferran Sayol                                                                                                                                                   |
|  92 |     26.137939 |    267.894057 | Birgit Lang                                                                                                                                                    |
|  93 |    557.265792 |    395.775142 | Matt Crook                                                                                                                                                     |
|  94 |    238.983021 |     11.960886 | C. Camilo Julián-Caballero                                                                                                                                     |
|  95 |    164.398540 |    462.875797 | Cathy                                                                                                                                                          |
|  96 |    722.159130 |    470.111864 | Matt Crook                                                                                                                                                     |
|  97 |    384.937086 |    723.291875 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
|  98 |     21.182235 |     30.348267 | Andy Wilson                                                                                                                                                    |
|  99 |    862.169742 |    391.179027 | Nobu Tamura (vectorized by A. Verrière)                                                                                                                        |
| 100 |     10.743554 |    540.943949 | NA                                                                                                                                                             |
| 101 |    649.592548 |    425.321730 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                           |
| 102 |    472.875241 |    565.710486 | NA                                                                                                                                                             |
| 103 |     34.114770 |     64.612424 | Scott Hartman                                                                                                                                                  |
| 104 |    708.337145 |     95.250433 | Margot Michaud                                                                                                                                                 |
| 105 |    510.908035 |    644.328826 | Matt Crook                                                                                                                                                     |
| 106 |    740.765827 |    576.680399 | Melissa Broussard                                                                                                                                              |
| 107 |    581.732266 |    450.811418 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 108 |    876.013303 |    443.467584 | Gabriela Palomo-Munoz                                                                                                                                          |
| 109 |    938.855722 |    503.079671 | Gareth Monger                                                                                                                                                  |
| 110 |    148.576989 |    776.198281 | Felix Vaux                                                                                                                                                     |
| 111 |    133.188412 |    377.077787 | T. Michael Keesey                                                                                                                                              |
| 112 |    791.295256 |    104.556335 | Andrew A. Farke                                                                                                                                                |
| 113 |    339.382540 |    581.648769 | Johan Lindgren, Michael W. Caldwell, Takuya Konishi, Luis M. Chiappe                                                                                           |
| 114 |    356.135058 |    181.847485 | Lukas Panzarin                                                                                                                                                 |
| 115 |     51.762209 |    485.769842 | NA                                                                                                                                                             |
| 116 |    174.719379 |    497.713934 | Gareth Monger                                                                                                                                                  |
| 117 |     16.743584 |    460.822500 | Christoph Schomburg                                                                                                                                            |
| 118 |    598.575960 |    786.888508 | NA                                                                                                                                                             |
| 119 |    692.912350 |    432.263090 | Nobu Tamura                                                                                                                                                    |
| 120 |    443.809360 |    435.167925 | Jagged Fang Designs                                                                                                                                            |
| 121 |    934.959483 |    371.516629 | Jagged Fang Designs                                                                                                                                            |
| 122 |    368.158165 |    710.324897 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                              |
| 123 |    223.030029 |    785.056863 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 124 |    457.433467 |     52.759943 | Bennet McComish, photo by Avenue                                                                                                                               |
| 125 |   1004.476707 |    541.814745 | Mathieu Pélissié                                                                                                                                               |
| 126 |    166.434131 |    505.561120 | Lafage                                                                                                                                                         |
| 127 |    584.690901 |    758.732911 | Beth Reinke                                                                                                                                                    |
| 128 |    965.109886 |    792.355289 | Maija Karala                                                                                                                                                   |
| 129 |    571.018883 |    157.087147 | Tracy A. Heath                                                                                                                                                 |
| 130 |    477.435659 |    248.015400 | Scott Hartman                                                                                                                                                  |
| 131 |    343.118860 |    280.805658 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                      |
| 132 |    763.150242 |    780.535627 | Kai R. Caspar                                                                                                                                                  |
| 133 |    793.936155 |     45.390355 | Matt Dempsey                                                                                                                                                   |
| 134 |    703.077180 |    786.510828 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
| 135 |    433.664123 |    598.146202 | Scott Hartman                                                                                                                                                  |
| 136 |    942.244582 |    531.072548 | Mathieu Pélissié                                                                                                                                               |
| 137 |    226.568691 |    205.412656 | Margot Michaud                                                                                                                                                 |
| 138 |    786.835003 |    777.218832 | Jagged Fang Designs                                                                                                                                            |
| 139 |     89.045044 |    226.830157 | Matt Crook                                                                                                                                                     |
| 140 |    452.390100 |     43.775165 | Andy Wilson                                                                                                                                                    |
| 141 |    535.560003 |    600.352302 | Agnello Picorelli                                                                                                                                              |
| 142 |    536.471637 |    120.824453 | FunkMonk                                                                                                                                                       |
| 143 |    125.962712 |    767.385051 | C. Camilo Julián-Caballero                                                                                                                                     |
| 144 |    130.131975 |    794.216419 | Taenadoman                                                                                                                                                     |
| 145 |    310.743964 |    574.080306 | Ferran Sayol                                                                                                                                                   |
| 146 |     48.385636 |    180.579724 | Robert Gay, modifed from Olegivvit                                                                                                                             |
| 147 |    416.203035 |    190.404415 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                |
| 148 |    519.720193 |    743.074365 | Auckland Museum                                                                                                                                                |
| 149 |    482.046387 |    648.516605 | Terpsichores                                                                                                                                                   |
| 150 |    616.298100 |    546.211352 | Karkemish (vectorized by T. Michael Keesey)                                                                                                                    |
| 151 |    445.390286 |    681.342678 | T. Michael Keesey                                                                                                                                              |
| 152 |    138.053694 |    640.219796 | Kai R. Caspar                                                                                                                                                  |
| 153 |    388.023493 |    465.083639 | Jaime Headden                                                                                                                                                  |
| 154 |    549.955354 |    294.614681 | Alexandre Vong                                                                                                                                                 |
| 155 |    145.971054 |    404.477333 | Gabriela Palomo-Munoz                                                                                                                                          |
| 156 |    412.956281 |    608.783959 | Pete Buchholz                                                                                                                                                  |
| 157 |    726.797271 |    562.085526 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 158 |    358.461508 |     74.292223 | Steven Coombs                                                                                                                                                  |
| 159 |    176.664569 |    708.296629 | Natasha Vitek                                                                                                                                                  |
| 160 |    998.424075 |    426.865420 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 161 |    863.761734 |    416.145642 | Milton Tan                                                                                                                                                     |
| 162 |    988.871574 |     51.388241 | Steven Traver                                                                                                                                                  |
| 163 |    693.968238 |    458.433289 | Scott Hartman                                                                                                                                                  |
| 164 |    991.667949 |     63.485738 | Matt Crook                                                                                                                                                     |
| 165 |     11.759293 |    205.345179 | Fritz Geller-Grimm (vectorized by T. Michael Keesey)                                                                                                           |
| 166 |    396.481165 |    173.377375 | Zimices                                                                                                                                                        |
| 167 |    661.481614 |    524.009297 | NA                                                                                                                                                             |
| 168 |    747.350148 |    326.402598 | Kamil S. Jaron                                                                                                                                                 |
| 169 |    235.026816 |     65.089152 | NASA                                                                                                                                                           |
| 170 |    517.241540 |    452.181010 | Prin Pattawaro (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 171 |    295.835089 |    717.926802 | Zimices                                                                                                                                                        |
| 172 |    976.500164 |    154.725850 | Scott Hartman                                                                                                                                                  |
| 173 |    760.077270 |     38.148909 | JCGiron                                                                                                                                                        |
| 174 |    812.079724 |    726.612810 | Nobu Tamura, vectorized by Zimices                                                                                                                             |
| 175 |    260.088966 |    574.494075 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 176 |    742.558764 |    207.953228 | Ferran Sayol                                                                                                                                                   |
| 177 |    103.639949 |    792.830779 | DW Bapst, modified from Ishitani et al. 2016                                                                                                                   |
| 178 |    918.328830 |    707.026385 | Matt Crook                                                                                                                                                     |
| 179 |    467.109908 |    161.304946 | Tracy A. Heath                                                                                                                                                 |
| 180 |    753.519689 |    578.250784 | wsnaccad                                                                                                                                                       |
| 181 |    153.051192 |    733.632363 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                          |
| 182 |    779.061696 |    112.240336 | Matt Crook                                                                                                                                                     |
| 183 |    717.275332 |     68.212211 | Jagged Fang Designs                                                                                                                                            |
| 184 |    467.948739 |    364.771961 | Scott Hartman                                                                                                                                                  |
| 185 |    177.138976 |    484.231882 | Collin Gross                                                                                                                                                   |
| 186 |    764.606726 |    559.937959 | Shyamal                                                                                                                                                        |
| 187 |    434.419720 |    372.038641 | Zimices                                                                                                                                                        |
| 188 |    834.606850 |    788.456752 | Zimices                                                                                                                                                        |
| 189 |     37.924580 |    686.470502 | Birgit Lang                                                                                                                                                    |
| 190 |    413.414177 |    152.592562 | Anna Willoughby                                                                                                                                                |
| 191 |    295.191123 |    759.722591 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 192 |    176.117955 |    615.080742 | CNZdenek                                                                                                                                                       |
| 193 |     16.812905 |    308.527630 | Cesar Julian                                                                                                                                                   |
| 194 |    677.495533 |     61.492769 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 195 |    962.183704 |    710.517302 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 196 |    142.549722 |    274.181479 | Walter Vladimir                                                                                                                                                |
| 197 |    290.501932 |    694.460401 | Tracy A. Heath                                                                                                                                                 |
| 198 |    836.495742 |    750.931438 | Iain Reid                                                                                                                                                      |
| 199 |    959.814733 |    241.626759 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                           |
| 200 |    830.503250 |    569.258919 | Erika Schumacher                                                                                                                                               |
| 201 |    667.189428 |    634.565423 | Matt Crook                                                                                                                                                     |
| 202 |    834.888708 |    655.717005 | Katie S. Collins                                                                                                                                               |
| 203 |    808.012152 |     70.886828 | Mathilde Cordellier                                                                                                                                            |
| 204 |     21.122525 |    325.293398 | Matt Crook                                                                                                                                                     |
| 205 |    709.647115 |    458.673453 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 206 |    220.799424 |    353.206449 | Armin Reindl                                                                                                                                                   |
| 207 |    846.437294 |    770.280906 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                  |
| 208 |    799.256728 |    459.539879 | Jagged Fang Designs                                                                                                                                            |
| 209 |    478.174414 |    341.074457 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 210 |    390.916972 |    583.691291 | Ferran Sayol                                                                                                                                                   |
| 211 |    768.398618 |    545.257191 | Zimices                                                                                                                                                        |
| 212 |    772.630002 |    469.437247 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 213 |     36.428190 |    620.482168 | Michael Scroggie                                                                                                                                               |
| 214 |    110.127917 |    170.350511 | Scott Hartman                                                                                                                                                  |
| 215 |     44.970501 |    203.896943 | J. J. Harrison (photo) & T. Michael Keesey                                                                                                                     |
| 216 |    271.361585 |    147.656109 | Steven Traver                                                                                                                                                  |
| 217 |    845.522729 |    404.461510 | Sarah Werning                                                                                                                                                  |
| 218 |    989.963374 |     97.050211 | Tracy A. Heath                                                                                                                                                 |
| 219 |    428.000457 |     65.162994 | Matt Crook                                                                                                                                                     |
| 220 |    463.488670 |    438.335966 | Crystal Maier                                                                                                                                                  |
| 221 |    847.963431 |    722.335684 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 222 |    134.194807 |    417.667295 | Armin Reindl                                                                                                                                                   |
| 223 |    829.936342 |    376.205047 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey     |
| 224 |      8.397005 |    659.131862 | Julio Garza                                                                                                                                                    |
| 225 |    484.691955 |    495.400393 | Ferran Sayol                                                                                                                                                   |
| 226 |    995.833225 |    788.139506 | Matt Martyniuk                                                                                                                                                 |
| 227 |    877.024813 |    570.154026 | Danielle Alba                                                                                                                                                  |
| 228 |    827.546987 |    106.777360 | Chase Brownstein                                                                                                                                               |
| 229 |    352.557426 |    473.838967 | Matt Crook                                                                                                                                                     |
| 230 |    991.785474 |    706.814945 | Markus A. Grohme                                                                                                                                               |
| 231 |    121.196146 |    256.259127 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                |
| 232 |    822.819492 |     78.322968 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey  |
| 233 |    686.756346 |    102.780199 | Matt Crook                                                                                                                                                     |
| 234 |    602.622119 |    234.425602 | Inessa Voet                                                                                                                                                    |
| 235 |     57.078619 |    366.521934 | Margot Michaud                                                                                                                                                 |
| 236 |    345.694333 |     19.310659 | NA                                                                                                                                                             |
| 237 |     92.905399 |    246.398879 | Gabriela Palomo-Munoz                                                                                                                                          |
| 238 |    155.116515 |    622.292518 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 239 |    921.674102 |    796.248076 | Erika Schumacher                                                                                                                                               |
| 240 |    692.582495 |    620.311621 | L. Shyamal                                                                                                                                                     |
| 241 |    739.647618 |    362.428018 | Scott Hartman                                                                                                                                                  |
| 242 |   1013.400480 |    711.469662 | Melissa Broussard                                                                                                                                              |
| 243 |    135.655039 |    447.703428 | Scott Hartman                                                                                                                                                  |
| 244 |    691.325316 |    288.251949 | Martin R. Smith, after Skovsted et al 2015                                                                                                                     |
| 245 |    458.783365 |    111.425905 | Steven Traver                                                                                                                                                  |
| 246 |    480.993137 |    789.975442 | NA                                                                                                                                                             |
| 247 |    499.295467 |      8.753605 | Steven Traver                                                                                                                                                  |
| 248 |    263.246229 |    634.956319 | Zimices                                                                                                                                                        |
| 249 |    940.682329 |    611.701617 | Gabriela Palomo-Munoz                                                                                                                                          |
| 250 |    739.197336 |    225.788795 | Christoph Schomburg                                                                                                                                            |
| 251 |    982.835643 |    518.195987 | Erika Schumacher                                                                                                                                               |
| 252 |    565.608573 |    506.339087 | Matt Crook                                                                                                                                                     |
| 253 |    118.958146 |    653.854035 | Blair Perry                                                                                                                                                    |
| 254 |    544.476821 |    446.019002 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                               |
| 255 |    900.332169 |    569.072849 | Margot Michaud                                                                                                                                                 |
| 256 |    614.278863 |    287.925988 | Christine Axon                                                                                                                                                 |
| 257 |    114.362375 |    624.543652 | Francesco “Architetto” Rollandin                                                                                                                               |
| 258 |    695.401611 |     46.595796 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 259 |    888.617082 |    770.793890 | T. Michael Keesey                                                                                                                                              |
| 260 |    985.448134 |    111.822134 | Steven Traver                                                                                                                                                  |
| 261 |    976.762266 |    607.235488 | Kamil S. Jaron                                                                                                                                                 |
| 262 |    207.766283 |    448.039855 | Ferran Sayol                                                                                                                                                   |
| 263 |    268.252333 |    293.285441 | Robert Gay                                                                                                                                                     |
| 264 |    690.926521 |    194.052274 | Steven Traver                                                                                                                                                  |
| 265 |    824.222582 |    710.863875 | NA                                                                                                                                                             |
| 266 |    417.792266 |    102.497743 | Tom Tarrant (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 267 |    276.511265 |    413.877879 | Sarah Werning                                                                                                                                                  |
| 268 |    151.639974 |    532.277771 | Shyamal                                                                                                                                                        |
| 269 |     36.199551 |    279.773389 | Ferran Sayol                                                                                                                                                   |
| 270 |    622.162599 |    666.712029 | Birgit Lang                                                                                                                                                    |
| 271 |    556.164574 |    188.214811 | Jack Mayer Wood                                                                                                                                                |
| 272 |    993.826694 |     14.463914 | Steven Traver                                                                                                                                                  |
| 273 |     19.342831 |    139.332433 | Ieuan Jones                                                                                                                                                    |
| 274 |    578.044696 |     35.311842 | Dantheman9758 (vectorized by T. Michael Keesey)                                                                                                                |
| 275 |     12.138458 |    424.860058 | (after Spotila 2004)                                                                                                                                           |
| 276 |   1015.507104 |    509.282015 | Dean Schnabel                                                                                                                                                  |
| 277 |    613.833568 |    190.449499 | Rebecca Groom                                                                                                                                                  |
| 278 |    886.773969 |    399.017383 | Cristopher Silva                                                                                                                                               |
| 279 |     42.580439 |    219.864581 | Jagged Fang Designs                                                                                                                                            |
| 280 |    438.275551 |    170.670969 | NA                                                                                                                                                             |
| 281 |    964.893022 |    751.304458 | Jagged Fang Designs                                                                                                                                            |
| 282 |    285.120560 |    783.506190 | Ferran Sayol                                                                                                                                                   |
| 283 |   1018.529108 |     61.912204 | kreidefossilien.de                                                                                                                                             |
| 284 |    497.719432 |    428.904943 | Tracy A. Heath                                                                                                                                                 |
| 285 |    598.299551 |    359.922133 | Dmitry Bogdanov, vectorized by Zimices                                                                                                                         |
| 286 |    862.172382 |    492.259253 | Zimices                                                                                                                                                        |
| 287 |    551.840648 |    682.278774 | Almandine (vectorized by T. Michael Keesey)                                                                                                                    |
| 288 |    374.229368 |    582.075582 | Smokeybjb (modified by T. Michael Keesey)                                                                                                                      |
| 289 |    781.727911 |     58.391671 | Gareth Monger                                                                                                                                                  |
| 290 |    215.887689 |    328.114860 | Jagged Fang Designs                                                                                                                                            |
| 291 |    125.615987 |    273.753528 | CDC (Alissa Eckert; Dan Higgins)                                                                                                                               |
| 292 |    785.771932 |    376.842051 | Scott Hartman                                                                                                                                                  |
| 293 |    787.589923 |    742.325512 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 294 |    295.671596 |    406.958183 | Metalhead64 (vectorized by T. Michael Keesey)                                                                                                                  |
| 295 |    794.551454 |    454.091947 | Zimices                                                                                                                                                        |
| 296 |    797.040773 |    565.453246 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 297 |    641.131119 |    673.392589 | Matt Crook                                                                                                                                                     |
| 298 |    250.694317 |    522.891554 |                                                                                                                                                                |
| 299 |     73.986422 |    197.549340 | Matt Martyniuk                                                                                                                                                 |
| 300 |    369.925794 |    285.474766 | T. Michael Keesey                                                                                                                                              |
| 301 |    981.075970 |    420.021983 | Gabriela Palomo-Munoz                                                                                                                                          |
| 302 |    848.486711 |    253.373494 | James R. Spotila and Ray Chatterji                                                                                                                             |
| 303 |    650.168857 |    528.104947 | Noah Schlottman, photo by Casey Dunn                                                                                                                           |
| 304 |     18.675415 |    290.667228 | Gareth Monger                                                                                                                                                  |
| 305 |    289.688636 |    429.848021 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                                |
| 306 |    969.464998 |    583.439536 | T. Michael Keesey                                                                                                                                              |
| 307 |    828.455411 |    276.753504 | Mathew Wedel                                                                                                                                                   |
| 308 |    766.482917 |    589.791634 | Noah Schlottman, photo by Hans De Blauwe                                                                                                                       |
| 309 |    194.981956 |    474.612909 | Birgit Lang, based on a photo by D. Sikes                                                                                                                      |
| 310 |    481.290586 |    154.740292 | Scott Hartman                                                                                                                                                  |
| 311 |    415.363416 |    179.713124 | Margot Michaud                                                                                                                                                 |
| 312 |    378.305401 |     82.073055 | Steven Traver                                                                                                                                                  |
| 313 |     20.161290 |    789.069564 | Chase Brownstein                                                                                                                                               |
| 314 |    971.429696 |    600.182778 | Alexis Simon                                                                                                                                                   |
| 315 |     87.412796 |    517.228424 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey    |
| 316 |    216.381322 |      5.192684 | Steven Traver                                                                                                                                                  |
| 317 |    839.559170 |    476.562273 | Gareth Monger                                                                                                                                                  |
| 318 |    584.191127 |    307.101839 | Konsta Happonen                                                                                                                                                |
| 319 |    670.570665 |    471.308473 | Zimices                                                                                                                                                        |
| 320 |    317.513643 |    188.563560 | Maxime Dahirel                                                                                                                                                 |
| 321 |    381.282702 |    196.514043 | Jagged Fang Designs                                                                                                                                            |
| 322 |    213.273695 |    628.380765 | Caleb M. Brown                                                                                                                                                 |
| 323 |     32.696336 |    128.575735 | Zimices                                                                                                                                                        |
| 324 |    162.713758 |    675.193203 | Kristina Gagalova                                                                                                                                              |
| 325 |    213.674631 |    710.711096 | Jagged Fang Designs                                                                                                                                            |
| 326 |    420.531769 |    757.905130 | Zachary Quigley                                                                                                                                                |
| 327 |    461.228189 |    573.203505 | NA                                                                                                                                                             |
| 328 |    884.646073 |    548.106353 | Gareth Monger                                                                                                                                                  |
| 329 |    260.537093 |    559.214639 | Zimices                                                                                                                                                        |
| 330 |    140.582765 |    686.131765 | Mattia Menchetti                                                                                                                                               |
| 331 |    881.357576 |    140.562838 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                                 |
| 332 |    648.330053 |    711.255544 | Steven Traver                                                                                                                                                  |
| 333 |   1013.686269 |    453.958105 | Scott Hartman                                                                                                                                                  |
| 334 |    993.737039 |    448.683990 | NA                                                                                                                                                             |
| 335 |    162.885142 |    715.389624 | Jagged Fang Designs                                                                                                                                            |
| 336 |    378.150905 |    474.993233 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 337 |    555.208866 |    368.122504 | Margot Michaud                                                                                                                                                 |
| 338 |     15.457625 |    580.553003 | Jaime Headden                                                                                                                                                  |
| 339 |    493.198755 |     26.267699 | NA                                                                                                                                                             |
| 340 |    208.061693 |    696.289728 | Zimices                                                                                                                                                        |
| 341 |    670.303975 |    496.324494 | Smokeybjb                                                                                                                                                      |
| 342 |    763.036093 |    368.697580 | Ignacio Contreras                                                                                                                                              |
| 343 |    436.880539 |    751.100638 | Scott Hartman                                                                                                                                                  |
| 344 |     47.529572 |     99.586541 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 345 |   1013.035352 |    475.932586 | Maija Karala                                                                                                                                                   |
| 346 |    867.815463 |    764.652136 | Zimices                                                                                                                                                        |
| 347 |    856.021053 |     45.682000 | Scott Hartman                                                                                                                                                  |
| 348 |    829.414854 |    250.170899 | Yusan Yang                                                                                                                                                     |
| 349 |    328.439430 |    280.817844 | Michelle Site                                                                                                                                                  |
| 350 |    886.963486 |    247.968072 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 351 |    166.212129 |    652.642881 | Steven Traver                                                                                                                                                  |
| 352 |    548.389680 |    106.301643 | FunkMonk (Michael B.H.; vectorized by T. Michael Keesey)                                                                                                       |
| 353 |    442.080659 |     49.783088 | Gareth Monger                                                                                                                                                  |
| 354 |    905.521851 |    528.100683 | Kailah Thorn & Ben King                                                                                                                                        |
| 355 |    233.619702 |    340.971722 | Margot Michaud                                                                                                                                                 |
| 356 |      7.683676 |    447.415010 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 357 |    316.656865 |    426.737849 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                    |
| 358 |    211.991165 |    571.019465 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                             |
| 359 |    398.396565 |    472.852331 | Jessica Anne Miller                                                                                                                                            |
| 360 |    282.911523 |    182.660388 | Kamil S. Jaron                                                                                                                                                 |
| 361 |    979.477698 |    432.680151 | Andy Wilson                                                                                                                                                    |
| 362 |    788.016111 |     41.711060 | Carlos Cano-Barbacil                                                                                                                                           |
| 363 |    366.363521 |    381.248952 | Mihai Dragos (vectorized by T. Michael Keesey)                                                                                                                 |
| 364 |    188.057625 |    231.037970 | Scott Hartman                                                                                                                                                  |
| 365 |    376.814313 |    569.716254 | Margot Michaud                                                                                                                                                 |
| 366 |    225.289563 |    774.873289 | Matt Crook                                                                                                                                                     |
| 367 |    816.761531 |    464.129550 | Steven Traver                                                                                                                                                  |
| 368 |    967.925237 |     86.184090 | Chris huh                                                                                                                                                      |
| 369 |    188.579707 |    569.832394 | Zimices                                                                                                                                                        |
| 370 |    204.536323 |    528.610767 | NA                                                                                                                                                             |
| 371 |    458.003293 |     24.986929 | Tyler Greenfield                                                                                                                                               |
| 372 |    755.619055 |    342.860328 | Margot Michaud                                                                                                                                                 |
| 373 |    378.417828 |     50.585642 | Michelle Site                                                                                                                                                  |
| 374 |    160.684190 |     86.599764 | Yan Wong                                                                                                                                                       |
| 375 |    784.714291 |    525.929130 | Andy Wilson                                                                                                                                                    |
| 376 |    305.372175 |    216.668927 | Margot Michaud                                                                                                                                                 |
| 377 |    103.713494 |    480.022779 | T. Michael Keesey                                                                                                                                              |
| 378 |    273.444819 |     90.086636 | Margot Michaud                                                                                                                                                 |
| 379 |    246.639746 |    103.193526 | Caleb M. Brown                                                                                                                                                 |
| 380 |    553.463984 |    216.331556 | Tracy A. Heath                                                                                                                                                 |
| 381 |    711.431808 |    563.752194 | Ghedo and T. Michael Keesey                                                                                                                                    |
| 382 |     19.922116 |    740.837854 | Andy Wilson                                                                                                                                                    |
| 383 |     80.909137 |    471.582909 | Matt Crook                                                                                                                                                     |
| 384 |    986.429302 |    535.070275 | Tasman Dixon                                                                                                                                                   |
| 385 |    438.484071 |    324.617873 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 386 |      8.928631 |     66.257560 | Chris huh                                                                                                                                                      |
| 387 |    621.328724 |    340.416846 | B. Duygu Özpolat                                                                                                                                               |
| 388 |    849.950025 |    779.455352 | Cesar Julian                                                                                                                                                   |
| 389 |    855.128309 |    730.787327 | Gareth Monger                                                                                                                                                  |
| 390 |     28.357192 |    182.010348 | Michael Scroggie                                                                                                                                               |
| 391 |    812.679669 |    276.391420 | Rebecca Groom                                                                                                                                                  |
| 392 |    194.243779 |     75.318927 | Scott Hartman                                                                                                                                                  |
| 393 |    955.679222 |    626.213326 | Matt Crook                                                                                                                                                     |
| 394 |    643.583030 |      5.333752 | Scott Hartman                                                                                                                                                  |
| 395 |    769.275221 |      7.929331 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 396 |    981.333304 |    674.107759 | Lafage                                                                                                                                                         |
| 397 |    292.640225 |    483.027783 | David Tana                                                                                                                                                     |
| 398 |    973.430248 |    171.145144 | Zimices                                                                                                                                                        |
| 399 |    990.314259 |    729.436413 | Tasman Dixon                                                                                                                                                   |
| 400 |    868.618263 |     51.601202 | NA                                                                                                                                                             |
| 401 |    123.370868 |    485.034221 | Tasman Dixon                                                                                                                                                   |
| 402 |    288.611515 |     13.023401 | Zimices                                                                                                                                                        |
| 403 |    196.428777 |    243.967694 | Markus A. Grohme                                                                                                                                               |
| 404 |    374.619523 |    704.068867 | Tasman Dixon                                                                                                                                                   |
| 405 |    776.445085 |    332.883220 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                               |
| 406 |    833.640327 |    389.485322 | Gareth Monger                                                                                                                                                  |
| 407 |    522.657320 |    380.234845 | Mattia Menchetti                                                                                                                                               |
| 408 |    330.437998 |    731.917268 | Xavier Giroux-Bougard                                                                                                                                          |
| 409 |    596.940019 |     32.076586 | Sharon Wegner-Larsen                                                                                                                                           |
| 410 |    108.270520 |    397.055803 | Roberto Díaz Sibaja                                                                                                                                            |
| 411 |    132.487303 |    157.235238 | Gabriela Palomo-Munoz                                                                                                                                          |
| 412 |    154.893906 |    788.191885 | Birgit Lang                                                                                                                                                    |
| 413 |   1009.978328 |     22.272530 | Sean McCann                                                                                                                                                    |
| 414 |    536.983213 |    378.987785 | Michael P. Taylor                                                                                                                                              |
| 415 |     43.992443 |     79.611421 | Michelle Site                                                                                                                                                  |
| 416 |    254.258446 |    161.156330 | Mark Miller                                                                                                                                                    |
| 417 |     36.365637 |    418.651865 | kreidefossilien.de                                                                                                                                             |
| 418 |    491.584309 |    439.959523 | Raven Amos                                                                                                                                                     |
| 419 |    108.730023 |     82.014577 | Ingo Braasch                                                                                                                                                   |
| 420 |    685.608846 |    610.112620 | Matt Crook                                                                                                                                                     |
| 421 |    596.779324 |     80.216178 | Ferran Sayol                                                                                                                                                   |
| 422 |    706.378400 |    428.253193 | Steven Coombs                                                                                                                                                  |
| 423 |    860.471430 |    477.926962 | Stuart Humphries                                                                                                                                               |
| 424 |    891.459024 |    374.539165 | Rebecca Groom                                                                                                                                                  |
| 425 |    110.555702 |    380.139536 | Sergio A. Muñoz-Gómez                                                                                                                                          |
| 426 |     63.745088 |    180.007321 | Tracy A. Heath                                                                                                                                                 |
| 427 |    903.536524 |    208.220860 | Tasman Dixon                                                                                                                                                   |
| 428 |    211.463877 |    551.753257 | Lukasiniho                                                                                                                                                     |
| 429 |    701.260829 |    396.168210 | Scott Hartman                                                                                                                                                  |
| 430 |    511.095408 |     30.470437 | Matt Crook                                                                                                                                                     |
| 431 |    539.427313 |     55.028452 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                  |
| 432 |    935.031992 |    516.818886 | Jagged Fang Designs                                                                                                                                            |
| 433 |    991.041019 |    769.077226 | Margot Michaud                                                                                                                                                 |
| 434 |    441.584304 |    147.447875 | Andy Wilson                                                                                                                                                    |
| 435 |    238.164288 |    466.539897 | Gareth Monger                                                                                                                                                  |
| 436 |    565.962066 |    100.175697 | NA                                                                                                                                                             |
| 437 |   1001.778090 |    757.431049 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                              |
| 438 |    923.396163 |    352.949159 | T. Michael Keesey (after Kukalová)                                                                                                                             |
| 439 |    413.826733 |    644.973925 | Matt Martyniuk                                                                                                                                                 |
| 440 |    330.308881 |     26.605134 | Margot Michaud                                                                                                                                                 |
| 441 |    552.313649 |    182.189440 | Steven Traver                                                                                                                                                  |
| 442 |    818.654389 |    533.780002 | Markus A. Grohme                                                                                                                                               |
| 443 |    678.164830 |    329.488054 | Matt Crook                                                                                                                                                     |
| 444 |    153.681881 |    423.496447 | Chloé Schmidt                                                                                                                                                  |
| 445 |    956.574730 |    542.918382 | Matt Crook                                                                                                                                                     |
| 446 |    932.747341 |    161.269810 | Charles R. Knight, vectorized by Zimices                                                                                                                       |
| 447 |    556.716705 |    599.143803 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                  |
| 448 |    661.007855 |    502.057281 | Scott Hartman                                                                                                                                                  |
| 449 |    998.479182 |     35.177963 | Alexandre Vong                                                                                                                                                 |
| 450 |    580.041259 |    115.056207 | Sarah Alewijnse                                                                                                                                                |
| 451 |    395.637776 |    655.517485 | Jimmy Bernot                                                                                                                                                   |
| 452 |    246.615695 |     57.597200 | Jagged Fang Designs                                                                                                                                            |
| 453 |   1005.549083 |    491.026640 | Scott Hartman                                                                                                                                                  |
| 454 |    677.418196 |     51.087639 | NA                                                                                                                                                             |
| 455 |    787.697209 |    312.147580 | Matt Crook                                                                                                                                                     |
| 456 |    516.047589 |    623.531922 | Christoph Schomburg                                                                                                                                            |
| 457 |    862.624179 |    655.937859 | T. Michael Keesey                                                                                                                                              |
| 458 |    397.444082 |    780.888398 | Anna Willoughby                                                                                                                                                |
| 459 |    719.589669 |    532.817895 | Zimices                                                                                                                                                        |
| 460 |    210.559197 |    162.328426 | Skye McDavid                                                                                                                                                   |
| 461 |    913.629051 |    422.581297 | Scott Hartman                                                                                                                                                  |
| 462 |    984.771956 |    752.786572 | Birgit Lang                                                                                                                                                    |
| 463 |    494.529513 |    472.951868 | Collin Gross                                                                                                                                                   |
| 464 |     65.562579 |     98.431412 | Roberto Díaz Sibaja                                                                                                                                            |
| 465 |    357.789408 |    738.977318 | Tasman Dixon                                                                                                                                                   |
| 466 |    848.444532 |     34.733293 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 467 |    484.329803 |    270.708522 | Andy Wilson                                                                                                                                                    |
| 468 |     23.301829 |    202.690296 | NA                                                                                                                                                             |
| 469 |    284.997587 |     33.977216 | J Levin W (illustration) and T. Michael Keesey (vectorization)                                                                                                 |
| 470 |    660.380209 |      3.279683 | Maija Karala                                                                                                                                                   |
| 471 |    838.572516 |     52.860647 | Ingo Braasch                                                                                                                                                   |
| 472 |    721.201134 |     53.485308 | Sharon Wegner-Larsen                                                                                                                                           |
| 473 |    881.888920 |    194.196988 | T. Michael Keesey                                                                                                                                              |
| 474 |    988.037578 |     89.752862 | Steven Traver                                                                                                                                                  |
| 475 |    460.077260 |    225.877017 | Jagged Fang Designs                                                                                                                                            |
| 476 |    890.322887 |    580.795560 | Chris huh                                                                                                                                                      |
| 477 |    489.469925 |    363.994900 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                             |
| 478 |    803.344287 |    606.608453 | Chuanixn Yu                                                                                                                                                    |
| 479 |      5.142011 |    285.690742 | Martin R. Smith                                                                                                                                                |
| 480 |    154.507599 |     97.184619 | Steven Coombs                                                                                                                                                  |
| 481 |    928.997535 |    784.852149 | Richard Parker (vectorized by T. Michael Keesey)                                                                                                               |
| 482 |    734.415711 |    387.789318 | Scott Hartman                                                                                                                                                  |
| 483 |    973.998564 |    568.019565 | Zimices                                                                                                                                                        |
| 484 |    900.210817 |    239.617001 | Matt Martyniuk                                                                                                                                                 |
| 485 |     74.783141 |    398.033144 | Gareth Monger                                                                                                                                                  |
| 486 |     12.770683 |    700.610866 | Ferran Sayol                                                                                                                                                   |
| 487 |    224.761716 |    187.525178 | Scott Hartman                                                                                                                                                  |
| 488 |    715.502152 |    554.179937 | Terpsichores                                                                                                                                                   |
| 489 |    889.949966 |    475.169189 | Gareth Monger                                                                                                                                                  |
| 490 |    809.993609 |    441.774060 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 491 |    277.659027 |    791.613046 | John Gould (vectorized by T. Michael Keesey)                                                                                                                   |
| 492 |    801.202112 |    499.344430 | Chris huh                                                                                                                                                      |
| 493 |     64.232352 |    731.937799 | Tasman Dixon                                                                                                                                                   |
| 494 |    393.563212 |    792.671702 | Armin Reindl                                                                                                                                                   |
| 495 |    193.202024 |    429.202347 | Pete Buchholz                                                                                                                                                  |
| 496 |    390.232275 |    180.812078 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 497 |    451.678171 |     60.693975 | Kai R. Caspar                                                                                                                                                  |
| 498 |    756.758416 |    194.687524 | Steven Traver                                                                                                                                                  |
| 499 |    586.646728 |    178.681153 | Lukasiniho                                                                                                                                                     |
| 500 |     79.084245 |    377.665271 | Oren Peles / vectorized by Yan Wong                                                                                                                            |
| 501 |    516.027464 |     44.014862 | Chase Brownstein                                                                                                                                               |
| 502 |    125.520986 |    491.729520 | Matt Crook                                                                                                                                                     |
| 503 |    982.870951 |    793.559290 | Katie S. Collins                                                                                                                                               |
| 504 |    749.251781 |    445.801926 | FJDegrange                                                                                                                                                     |
| 505 |    467.089708 |      8.933824 | Kent Elson Sorgon                                                                                                                                              |
| 506 |    864.825648 |    713.436341 | Cristian Osorio & Paula Carrera, Proyecto Carnivoros Australes (www.carnivorosaustrales.org)                                                                   |
| 507 |     13.853907 |    613.285953 | T. Michael Keesey                                                                                                                                              |
| 508 |    539.665701 |    161.958896 | Mathew Wedel                                                                                                                                                   |
| 509 |    416.492673 |    163.748311 | Chris Hay                                                                                                                                                      |
| 510 |    189.868614 |    486.981855 | Matt Crook                                                                                                                                                     |
| 511 |    621.831730 |    574.642108 | Matt Crook                                                                                                                                                     |
| 512 |    476.744889 |    753.825516 | David Orr                                                                                                                                                      |
| 513 |    352.011119 |    784.705352 | T. Michael Keesey                                                                                                                                              |
| 514 |    880.786186 |    223.432594 | Arthur S. Brum                                                                                                                                                 |
| 515 |    560.433235 |    127.697272 | Rebecca Groom                                                                                                                                                  |
| 516 |    786.379212 |    120.306494 | Steven Traver                                                                                                                                                  |
| 517 |    664.318116 |    593.929700 | Matt Crook                                                                                                                                                     |
| 518 |    546.553335 |     34.773377 | Alyssa Bell & Luis Chiappe 2015, dx.doi.org/10.1371/journal.pone.0141690                                                                                       |
| 519 |    597.021109 |    249.337548 | Mette Aumala                                                                                                                                                   |
| 520 |    312.573126 |    308.302528 | Jagged Fang Designs                                                                                                                                            |
| 521 |    177.957327 |    522.316293 | Zimices                                                                                                                                                        |
| 522 |    695.702619 |     75.834607 | Benjamin Monod-Broca                                                                                                                                           |
| 523 |    498.327957 |    512.761431 | Harold N Eyster                                                                                                                                                |
| 524 |    174.849694 |     84.077211 | NA                                                                                                                                                             |
| 525 |    565.565292 |    308.323779 | Scott Reid                                                                                                                                                     |
| 526 |    291.607328 |    592.286116 | Tauana J. Cunha                                                                                                                                                |
| 527 |    501.482487 |    403.002653 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
| 528 |    662.488324 |     73.408222 | Mathieu Basille                                                                                                                                                |
| 529 |    537.195797 |    363.919624 | Zimices                                                                                                                                                        |
| 530 |    156.971619 |    305.653086 | NA                                                                                                                                                             |
| 531 |    368.606796 |    794.257785 | Michael “FunkMonk” B. H. (vectorized by T. Michael Keesey)                                                                                                     |
| 532 |     77.699401 |    466.679793 | Zimices                                                                                                                                                        |
| 533 |    582.478746 |    672.906222 | Beth Reinke                                                                                                                                                    |
| 534 |    863.582229 |    294.385665 | Elizabeth Parker                                                                                                                                               |
| 535 |    846.425388 |    641.049271 | C. Camilo Julián-Caballero                                                                                                                                     |
| 536 |    696.961750 |    613.861537 | Beth Reinke                                                                                                                                                    |
| 537 |    553.294116 |      7.435062 | Xavier Giroux-Bougard                                                                                                                                          |
| 538 |    501.431628 |    236.400759 | Matt Crook                                                                                                                                                     |
| 539 |    765.191230 |    213.132339 | T. Michael Keesey                                                                                                                                              |
| 540 |    946.113524 |      4.144584 | NA                                                                                                                                                             |
| 541 |    224.475555 |    108.805024 | Steven Coombs                                                                                                                                                  |
| 542 |    424.097686 |    663.352532 | Chris huh                                                                                                                                                      |
| 543 |     51.334145 |    442.038752 | Dean Schnabel                                                                                                                                                  |
| 544 |    444.837189 |    107.278965 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 545 |    411.645635 |    658.136940 | Ferran Sayol                                                                                                                                                   |
| 546 |     31.264706 |    165.103386 | Zimices                                                                                                                                                        |
| 547 |     55.534080 |     17.564352 | Iain Reid                                                                                                                                                      |
| 548 |    128.922458 |    782.927227 | Katie S. Collins                                                                                                                                               |
| 549 |    847.727925 |    107.086750 | Margot Michaud                                                                                                                                                 |
| 550 |    286.228621 |     45.882057 | Matthew E. Clapham                                                                                                                                             |
| 551 |    421.109824 |     88.331229 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 552 |    185.680803 |      6.626505 | T. Michael Keesey                                                                                                                                              |
| 553 |    425.002663 |    259.340575 | Matt Crook                                                                                                                                                     |
| 554 |    863.882868 |    791.644368 | Emily Jane McTavish, from <http://en.wikipedia.org/wiki/File:Coccolithus_pelagicus.jpg>                                                                        |
| 555 |    956.402971 |    109.981119 | Neil Kelley                                                                                                                                                    |
| 556 |    742.712827 |    368.619534 | Jagged Fang Designs                                                                                                                                            |
| 557 |    653.948858 |    576.424239 | Estelle Bourdon                                                                                                                                                |
| 558 |     60.954187 |    219.561482 | Margot Michaud                                                                                                                                                 |
| 559 |    489.069170 |    328.655175 | Steven Traver                                                                                                                                                  |
| 560 |    817.146267 |    489.407573 | Raven Amos                                                                                                                                                     |
| 561 |    160.695846 |    124.814808 | Kai R. Caspar                                                                                                                                                  |
| 562 |    788.963716 |    253.595112 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                          |
| 563 |    846.612958 |    122.405426 | Zimices                                                                                                                                                        |
| 564 |    818.733806 |    676.525938 | Cesar Julian                                                                                                                                                   |
| 565 |    524.917537 |    664.504144 | Matt Crook                                                                                                                                                     |
| 566 |    367.678135 |    367.840509 | Scott Hartman                                                                                                                                                  |
| 567 |    833.824193 |    666.918605 | Scott Hartman                                                                                                                                                  |
| 568 |    256.193430 |    137.674440 | Gareth Monger                                                                                                                                                  |
| 569 |    123.402831 |    145.177290 | Scott Hartman                                                                                                                                                  |
| 570 |    448.439271 |    788.518103 | Margot Michaud                                                                                                                                                 |
| 571 |    839.988003 |    731.284638 | Margot Michaud                                                                                                                                                 |
| 572 |     29.378433 |    702.553445 | Margot Michaud                                                                                                                                                 |
| 573 |    356.887459 |    324.647162 | Ferran Sayol                                                                                                                                                   |
| 574 |    311.818361 |    729.594448 | Jagged Fang Designs                                                                                                                                            |
| 575 |    860.796648 |    624.060881 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 576 |    671.719097 |    310.657048 | Tasman Dixon                                                                                                                                                   |
| 577 |    690.891497 |    476.925188 | Steven Traver                                                                                                                                                  |
| 578 |     91.153422 |    485.887925 | Matt Crook                                                                                                                                                     |
| 579 |    428.111492 |    172.019467 | Felix Vaux                                                                                                                                                     |
| 580 |   1012.111888 |    257.410284 | Birgit Lang                                                                                                                                                    |
| 581 |    948.875975 |    138.770859 | Jagged Fang Designs                                                                                                                                            |
| 582 |    802.698652 |    358.551726 | Katie S. Collins                                                                                                                                               |
| 583 |    664.168910 |    650.341415 | Steven Traver                                                                                                                                                  |
| 584 |   1007.442584 |     65.103654 | Caleb M. Brown                                                                                                                                                 |
| 585 |    124.816093 |    601.150766 | Bruno C. Vellutini                                                                                                                                             |
| 586 |    943.115378 |    620.757388 | Jagged Fang Designs                                                                                                                                            |
| 587 |    692.160159 |    151.094597 | Davidson Sodré                                                                                                                                                 |
| 588 |    594.275388 |     67.340294 | Matt Crook                                                                                                                                                     |
| 589 |    797.028537 |    533.383022 | Zimices                                                                                                                                                        |
| 590 |    677.966545 |    401.730425 | Gareth Monger                                                                                                                                                  |
| 591 |    705.271080 |    586.109779 | NA                                                                                                                                                             |
| 592 |    800.556771 |    763.103800 | Steven Coombs                                                                                                                                                  |
| 593 |    334.091746 |     14.081299 | Anthony Caravaggi                                                                                                                                              |
| 594 |    159.938792 |    326.894070 | xgirouxb                                                                                                                                                       |
| 595 |    644.157619 |    741.451327 | Tasman Dixon                                                                                                                                                   |
| 596 |    962.404178 |     13.842173 | Andy Wilson                                                                                                                                                    |
| 597 |    603.691936 |    524.253169 | Bill Bouton (source photo) & T. Michael Keesey (vectorization)                                                                                                 |
| 598 |    373.810281 |    439.993918 | Joe Schneid (vectorized by T. Michael Keesey)                                                                                                                  |
| 599 |    378.656974 |    747.048999 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                |
| 600 |    227.350551 |    532.718296 | Yan Wong                                                                                                                                                       |
| 601 |   1008.589834 |    117.657273 | Crystal Maier                                                                                                                                                  |
| 602 |     47.781092 |    657.856088 | Lukasiniho                                                                                                                                                     |
| 603 |    846.612052 |    711.152567 | Matt Wilkins                                                                                                                                                   |
| 604 |    633.174822 |     14.264459 | Ignacio Contreras                                                                                                                                              |
| 605 |    245.557808 |    589.877360 | Lukasiniho                                                                                                                                                     |
| 606 |    380.921475 |    698.109761 | Shyamal                                                                                                                                                        |
| 607 |    378.721305 |    324.978237 | Ferran Sayol                                                                                                                                                   |
| 608 |    643.712144 |    227.207747 | Jagged Fang Designs                                                                                                                                            |
| 609 |    359.041159 |    610.810844 | Zimices                                                                                                                                                        |
| 610 |    256.149154 |    443.685143 | Trond R. Oskars                                                                                                                                                |
| 611 |    885.240386 |    420.016520 | Maija Karala                                                                                                                                                   |
| 612 |    233.765297 |    331.022549 | Andy Wilson                                                                                                                                                    |
| 613 |    881.596420 |    128.232110 | Xavier Giroux-Bougard                                                                                                                                          |
| 614 |    416.266330 |    213.425207 | Scott Hartman                                                                                                                                                  |
| 615 |    548.900299 |    382.341046 | Shyamal                                                                                                                                                        |
| 616 |    562.167455 |    752.505407 | Sarah Werning                                                                                                                                                  |
| 617 |     62.738751 |    507.173428 | Gabriela Palomo-Munoz                                                                                                                                          |
| 618 |     21.118853 |      8.556092 | Scott Hartman                                                                                                                                                  |
| 619 |    413.032206 |     65.068804 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                            |
| 620 |   1018.409302 |    738.204134 | Ferran Sayol                                                                                                                                                   |
| 621 |    816.710835 |    776.302763 | NA                                                                                                                                                             |
| 622 |    829.195872 |    794.785499 | Jose Carlos Arenas-Monroy                                                                                                                                      |
| 623 |    975.863204 |    505.247671 | NA                                                                                                                                                             |
| 624 |    656.474651 |    669.691987 | NA                                                                                                                                                             |
| 625 |    584.708495 |    521.163246 | Rebecca Groom                                                                                                                                                  |
| 626 |    213.881315 |    470.837985 | Jagged Fang Designs                                                                                                                                            |
| 627 |    520.010374 |    360.286844 | NA                                                                                                                                                             |
| 628 |    452.185476 |     16.535188 | Tasman Dixon                                                                                                                                                   |
| 629 |    546.104316 |    742.847494 | Ferran Sayol                                                                                                                                                   |
| 630 |    169.204085 |    310.736043 | Gopal Murali                                                                                                                                                   |
| 631 |    420.249370 |    383.579059 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 632 |     87.929865 |    174.106758 | Jagged Fang Designs                                                                                                                                            |
| 633 |    827.349962 |    560.705513 | Jagged Fang Designs                                                                                                                                            |
| 634 |    216.690073 |     48.348073 | Jagged Fang Designs                                                                                                                                            |
| 635 |    233.038788 |    374.892901 | T. Michael Keesey                                                                                                                                              |
| 636 |    395.203280 |    392.724013 | Matt Crook                                                                                                                                                     |
| 637 |    693.364856 |    413.212989 | Jagged Fang Designs                                                                                                                                            |
| 638 |    434.807750 |    745.355688 | Zimices                                                                                                                                                        |
| 639 |    529.419926 |    406.348670 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey        |
| 640 |    158.459551 |    697.568800 | Kai R. Caspar                                                                                                                                                  |
| 641 |    562.294363 |    586.756768 | Beth Reinke                                                                                                                                                    |
| 642 |    299.049637 |    317.009321 | Gareth Monger                                                                                                                                                  |
| 643 |    455.526653 |    166.181904 | Michael Scroggie                                                                                                                                               |
| 644 |    333.546320 |    791.131008 | Konsta Happonen, from a CC-BY-NC image by pelhonen on iNaturalist                                                                                              |
| 645 |    428.379862 |     13.491412 | Mason McNair                                                                                                                                                   |
| 646 |    958.694999 |    125.408343 | Noah Schlottman, photo by Antonio Guillén                                                                                                                      |
| 647 |    536.882595 |    629.472479 | Matus Valach                                                                                                                                                   |
| 648 |     20.398045 |    761.677752 | Christoph Schomburg                                                                                                                                            |
| 649 |    544.419750 |    607.580831 | Steven Traver                                                                                                                                                  |
| 650 |    170.504149 |    206.334978 | Matt Crook                                                                                                                                                     |
| 651 |    696.421938 |    383.841010 | Matt Crook                                                                                                                                                     |
| 652 |    199.029441 |    518.172462 | Iain Reid                                                                                                                                                      |
| 653 |    963.804785 |    532.608622 | David Orr                                                                                                                                                      |
| 654 |    506.901540 |    111.166351 | Matt Crook                                                                                                                                                     |
| 655 |     19.736513 |    404.107917 | Jebulon (vectorized by T. Michael Keesey)                                                                                                                      |
| 656 |    571.311646 |    794.588732 | Smokeybjb                                                                                                                                                      |
| 657 |    826.254717 |    684.770592 | Geoff Shaw                                                                                                                                                     |
| 658 |    754.924318 |    238.304338 | Chloé Schmidt                                                                                                                                                  |
| 659 |    174.835610 |    116.107431 | T. Michael Keesey                                                                                                                                              |
| 660 |    513.515339 |    695.515583 | L. Shyamal                                                                                                                                                     |
| 661 |    576.163640 |    111.978339 | Markus A. Grohme                                                                                                                                               |
| 662 |    785.386026 |    554.623667 | Matt Crook                                                                                                                                                     |
| 663 |    589.961705 |    497.807671 | Cagri Cevrim                                                                                                                                                   |
| 664 |    931.421774 |    773.594438 | Joanna Wolfe                                                                                                                                                   |
| 665 |     87.592476 |    218.326718 | Ignacio Contreras                                                                                                                                              |
| 666 |    709.080918 |    280.323185 | Jagged Fang Designs                                                                                                                                            |
| 667 |    554.114647 |    321.370852 | Jagged Fang Designs                                                                                                                                            |
| 668 |    954.725107 |    180.235866 | Michael P. Taylor                                                                                                                                              |
| 669 |    574.254991 |    146.508352 | Michelle Site                                                                                                                                                  |
| 670 |    239.944427 |    532.685863 | Margot Michaud                                                                                                                                                 |
| 671 |    603.178144 |    465.038151 | Ville-Veikko Sinkkonen                                                                                                                                         |
| 672 |    332.891015 |    477.879642 | Original scheme by ‘Haplochromis’, vectorized by Roberto Díaz Sibaja                                                                                           |
| 673 |    543.734348 |    484.877394 | NA                                                                                                                                                             |
| 674 |    772.802584 |    521.218916 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                            |
| 675 |    752.027548 |     22.000395 | Matt Wilkins                                                                                                                                                   |
| 676 |    397.258014 |    687.613796 | Margot Michaud                                                                                                                                                 |
| 677 |    286.037663 |    194.792353 | Gareth Monger                                                                                                                                                  |
| 678 |    648.480961 |    776.677366 | David Tana                                                                                                                                                     |
| 679 |    703.179083 |    286.724523 | Zimices                                                                                                                                                        |
| 680 |    570.467550 |    366.599463 | Kai R. Caspar                                                                                                                                                  |
| 681 |    717.478283 |    793.990764 | Robert Gay, modified from FunkMonk (Michael B.H.) and T. Michael Keesey.                                                                                       |
| 682 |    995.628394 |    177.550864 | NA                                                                                                                                                             |
| 683 |    561.059056 |    615.046512 | Andrés Sánchez                                                                                                                                                 |
| 684 |     64.833841 |    740.755005 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                    |
| 685 |    164.315257 |    220.385352 | Chris huh                                                                                                                                                      |
| 686 |    452.466392 |    755.285760 | Alex Slavenko                                                                                                                                                  |
| 687 |    463.088630 |    627.703802 | Matt Crook                                                                                                                                                     |
| 688 |    493.591299 |    353.521105 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                   |
| 689 |    715.610045 |    418.907453 | Scott Hartman                                                                                                                                                  |
| 690 |    635.083609 |    536.357442 | Steven Traver                                                                                                                                                  |
| 691 |    379.859826 |    156.408699 | Gareth Monger                                                                                                                                                  |
| 692 |    737.604400 |    184.142714 | T. Michael Keesey                                                                                                                                              |
| 693 |    331.827663 |    708.974705 | Gareth Monger                                                                                                                                                  |
| 694 |    886.242496 |    623.611183 | C. Camilo Julián-Caballero                                                                                                                                     |
| 695 |    764.735613 |     50.862814 | Eduard Solà Vázquez, vectorised by Yan Wong                                                                                                                    |
| 696 |   1004.011653 |    139.352469 | Margot Michaud                                                                                                                                                 |
| 697 |    173.626034 |    189.286788 | Scott Hartman                                                                                                                                                  |
| 698 |    663.836996 |    324.434917 | Andy Wilson                                                                                                                                                    |
| 699 |    217.264919 |    196.770880 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 700 |    928.196393 |    617.214242 | NA                                                                                                                                                             |
| 701 |    324.382506 |    777.564347 | NA                                                                                                                                                             |
| 702 |     17.664487 |     77.010761 | Zimices                                                                                                                                                        |
| 703 |    913.937200 |      2.851615 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                     |
| 704 |    837.674739 |     65.110418 | Mali’o Kodis, photograph by Aqua-Photos (<http://www.flickr.com/people/undervannsfotografen/>)                                                                 |
| 705 |   1015.679975 |    571.509312 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 706 |    535.511522 |    681.302391 | NA                                                                                                                                                             |
| 707 |     82.616280 |    429.455306 | NA                                                                                                                                                             |
| 708 |    753.656572 |    390.135212 | Matt Crook                                                                                                                                                     |
| 709 |    306.849631 |     37.243115 | Mali’o Kodis, photograph by Derek Keats (<http://www.flickr.com/photos/dkeats/>)                                                                               |
| 710 |    276.775040 |    476.076767 | Margot Michaud                                                                                                                                                 |
| 711 |    926.607546 |    767.222931 | Jagged Fang Designs                                                                                                                                            |
| 712 |     47.849853 |    642.892882 | Almandine (vectorized by T. Michael Keesey)                                                                                                                    |
| 713 |    990.428498 |    576.704288 | Michael Scroggie                                                                                                                                               |
| 714 |    801.513763 |    750.884793 | Steven Traver                                                                                                                                                  |
| 715 |    738.507998 |     45.971844 | NA                                                                                                                                                             |
| 716 |    344.106080 |    322.671597 | Crystal Maier                                                                                                                                                  |
| 717 |    715.861238 |    300.290929 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                               |
| 718 |    402.207948 |     70.708842 | FunkMonk                                                                                                                                                       |
| 719 |    878.250474 |    427.987808 | Tauana J. Cunha                                                                                                                                                |
| 720 |    561.688393 |    328.486420 | Mo Hassan                                                                                                                                                      |
| 721 |    851.135175 |    650.873892 | Shyamal                                                                                                                                                        |
| 722 |    481.779201 |      4.939424 | Ieuan Jones                                                                                                                                                    |
| 723 |    674.034383 |    617.772440 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                           |
| 724 |     76.450520 |    236.444446 | Markus A. Grohme                                                                                                                                               |
| 725 |     37.636841 |    173.000331 | Erika Schumacher                                                                                                                                               |
| 726 |     17.323350 |    238.060170 | Maky (vectorization), Gabriella Skollar (photography), Rebecca Lewis (editing)                                                                                 |
| 727 |    488.807478 |    110.207294 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 728 |    646.305646 |    727.811222 | NA                                                                                                                                                             |
| 729 |    388.816950 |      4.520278 | Jagged Fang Designs                                                                                                                                            |
| 730 |    756.878515 |    567.313186 | NA                                                                                                                                                             |
| 731 |    624.902057 |    283.894070 | Fcb981 (vectorized by T. Michael Keesey)                                                                                                                       |
| 732 |    285.212686 |    622.996694 | Jagged Fang Designs                                                                                                                                            |
| 733 |     94.731953 |    363.964731 | Zimices                                                                                                                                                        |
| 734 |    597.060132 |    307.407647 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 735 |    888.554290 |    290.195401 | L. Shyamal                                                                                                                                                     |
| 736 |    577.151681 |    194.693991 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 737 |    553.349597 |    628.998758 | Benjamint444                                                                                                                                                   |
| 738 |    786.329127 |    349.964255 | Matt Crook                                                                                                                                                     |
| 739 |    496.796990 |    778.492347 | T. Michael Keesey                                                                                                                                              |
| 740 |    110.727825 |    152.581660 | Gareth Monger                                                                                                                                                  |
| 741 |    249.583592 |    473.845521 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 742 |    560.034302 |    482.306656 | NA                                                                                                                                                             |
| 743 |    319.424673 |    472.883157 | Zimices                                                                                                                                                        |
| 744 |    568.107007 |     80.112750 | NA                                                                                                                                                             |
| 745 |    411.053690 |    327.392876 | Andy Wilson                                                                                                                                                    |
| 746 |    588.760940 |    351.503452 | Gareth Monger                                                                                                                                                  |
| 747 |    515.884784 |    168.850099 | Burton Robert, USFWS                                                                                                                                           |
| 748 |    737.208856 |    149.750087 | Gareth Monger                                                                                                                                                  |
| 749 |    578.017268 |    578.753225 | Steven Traver                                                                                                                                                  |
| 750 |    230.628624 |    707.019654 | Armin Reindl                                                                                                                                                   |
| 751 |     45.351187 |    260.203660 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                              |
| 752 |    919.979743 |    232.681062 | Matt Crook                                                                                                                                                     |
| 753 |    908.493195 |    631.060947 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 754 |    406.508806 |    729.531546 | Kai R. Caspar                                                                                                                                                  |
| 755 |     11.384278 |     91.676226 | Christoph Schomburg                                                                                                                                            |
| 756 |    576.300283 |    734.300729 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 757 |   1009.204783 |    207.537353 | Joanna Wolfe                                                                                                                                                   |
| 758 |    952.859400 |    572.463771 | Dean Schnabel                                                                                                                                                  |
| 759 |    337.790456 |    370.916940 | Estelle Bourdon                                                                                                                                                |
| 760 |    787.971873 |    388.080003 | Dean Schnabel                                                                                                                                                  |
| 761 |    122.212263 |    614.125209 | Jagged Fang Designs                                                                                                                                            |
| 762 |    581.359378 |    406.375141 | Gabriela Palomo-Munoz                                                                                                                                          |
| 763 |    650.213561 |    491.687848 | Margot Michaud                                                                                                                                                 |
| 764 |    165.985869 |    143.122585 | NA                                                                                                                                                             |
| 765 |    596.257172 |    117.020833 | Conty (vectorized by T. Michael Keesey)                                                                                                                        |
| 766 |    526.279893 |    736.829384 | Chris huh                                                                                                                                                      |
| 767 |    983.991501 |    625.283074 | Matt Crook                                                                                                                                                     |
| 768 |    966.802117 |    114.372486 | FunkMonk                                                                                                                                                       |
| 769 |    596.633274 |    795.767276 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 770 |    404.710248 |    198.919751 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 771 |    446.875549 |    657.946852 | Matt Crook                                                                                                                                                     |
| 772 |    250.830926 |    794.591766 | Yan Wong                                                                                                                                                       |
| 773 |    844.486666 |    591.871137 | Manabu Sakamoto                                                                                                                                                |
| 774 |    591.829571 |     87.894391 | NA                                                                                                                                                             |
| 775 |    704.700433 |    336.762984 | NA                                                                                                                                                             |
| 776 |    513.337174 |    406.075338 | Pranav Iyer (grey ideas)                                                                                                                                       |
| 777 |    428.297600 |    735.328017 | Scott Hartman                                                                                                                                                  |
| 778 |    625.105313 |     63.445573 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                  |
| 779 |    543.314893 |    648.520848 | Ignacio Contreras                                                                                                                                              |
| 780 |    858.460161 |     82.404491 | NA                                                                                                                                                             |
| 781 |    995.886253 |    745.681447 | Rene Martin                                                                                                                                                    |
| 782 |    208.180910 |    109.269543 | Andrés Sánchez                                                                                                                                                 |
| 783 |    710.867211 |    434.778649 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 784 |    211.149295 |    460.086758 | Christoph Schomburg                                                                                                                                            |
| 785 |    706.435218 |    448.326805 | Beth Reinke                                                                                                                                                    |
| 786 |     67.355491 |    650.635869 | Chris huh                                                                                                                                                      |
| 787 |    784.749721 |    792.219751 | Steven Traver                                                                                                                                                  |
| 788 |    646.925665 |    685.976962 | Margot Michaud                                                                                                                                                 |
| 789 |    600.868109 |    283.051723 | Margot Michaud                                                                                                                                                 |
| 790 |    236.355179 |    188.042034 | Martin R. Smith                                                                                                                                                |
| 791 |    744.419627 |      3.374929 | Chris huh                                                                                                                                                      |
| 792 |    364.478180 |    196.973183 | Steven Traver                                                                                                                                                  |
| 793 |      9.100281 |    386.056792 | Ferran Sayol                                                                                                                                                   |
| 794 |     75.783743 |    322.259451 | T. Michael Keesey                                                                                                                                              |
| 795 |    229.160899 |    573.996305 | Scott Hartman                                                                                                                                                  |
| 796 |    357.820132 |      5.178741 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                              |
| 797 |    524.373564 |    437.005024 | NA                                                                                                                                                             |
| 798 |    429.454378 |    314.698977 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 799 |    915.113602 |    128.070452 | NA                                                                                                                                                             |
| 800 |    885.870442 |    483.139290 | Jagged Fang Designs                                                                                                                                            |
| 801 |    981.480548 |     24.669985 | Terpsichores                                                                                                                                                   |
| 802 |    879.468875 |    789.519708 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 803 |    924.441512 |    579.619947 | Zimices                                                                                                                                                        |
| 804 |    338.742515 |    190.100621 | LeonardoG (photography) and T. Michael Keesey (vectorization)                                                                                                  |
| 805 |    866.029724 |    560.387031 | Jagged Fang Designs                                                                                                                                            |
| 806 |   1014.138061 |     78.336670 | Margot Michaud                                                                                                                                                 |
| 807 |     73.448563 |    230.332468 | Zimices                                                                                                                                                        |
| 808 |    766.154157 |    206.024447 | Skye M                                                                                                                                                         |
| 809 |    521.716278 |    220.710977 | Zimices                                                                                                                                                        |
| 810 |    270.204624 |     56.679309 | Zimices                                                                                                                                                        |
| 811 |    761.043716 |    532.803750 | Kai R. Caspar                                                                                                                                                  |
| 812 |    916.196322 |    113.389805 | Gareth Monger                                                                                                                                                  |
| 813 |    645.439494 |    697.945535 | Ferran Sayol                                                                                                                                                   |
| 814 |    495.339532 |    551.170535 | Yan Wong                                                                                                                                                       |
| 815 |    909.173799 |    103.162381 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                            |
| 816 |    494.936863 |    123.535425 | Collin Gross                                                                                                                                                   |
| 817 |    257.172141 |    174.174668 | Jagged Fang Designs                                                                                                                                            |
| 818 |    820.860158 |    116.131006 | Chris huh                                                                                                                                                      |
| 819 |    327.126045 |    586.497996 | Filip em                                                                                                                                                       |
| 820 |    345.290667 |    795.104113 | Gareth Monger                                                                                                                                                  |
| 821 |    409.431288 |    568.121964 | Steven Coombs                                                                                                                                                  |
| 822 |    150.344234 |    754.328959 | Vanessa Guerra                                                                                                                                                 |
| 823 |    503.655140 |    386.335127 | Sarah Werning                                                                                                                                                  |
| 824 |    141.373204 |    100.591468 | Dean Schnabel                                                                                                                                                  |
| 825 |    740.286524 |    540.949316 | Matt Crook                                                                                                                                                     |
| 826 |    141.175671 |    667.739067 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                       |
| 827 |     15.952388 |    359.364885 | Zimices                                                                                                                                                        |
| 828 |    521.013178 |    560.402475 | NA                                                                                                                                                             |
| 829 |    861.555491 |    228.260395 | Jake Warner                                                                                                                                                    |
| 830 |    848.561403 |    584.653675 | CNZdenek                                                                                                                                                       |
| 831 |    834.334157 |    507.939234 | Sam Droege (photo) and T. Michael Keesey (vectorization)                                                                                                       |
| 832 |    717.403418 |    599.524313 | Steven Traver                                                                                                                                                  |
| 833 |    674.120516 |    452.661495 | Chris huh                                                                                                                                                      |
| 834 |    497.550224 |    665.772650 | DW Bapst (modified from Mitchell 1990)                                                                                                                         |
| 835 |    272.418712 |    543.214226 | Ewald Rübsamen                                                                                                                                                 |
| 836 |    845.126718 |    238.801851 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                  |
| 837 |    978.675484 |    141.832206 | NA                                                                                                                                                             |
| 838 |      8.207246 |    470.624137 | Alexandre Vong                                                                                                                                                 |
| 839 |    787.106108 |    539.752753 | Steven Traver                                                                                                                                                  |
| 840 |    502.533201 |    457.701608 | Chloé Schmidt                                                                                                                                                  |
| 841 |    615.282564 |    557.010209 | Kevin Sánchez                                                                                                                                                  |
| 842 |    175.469176 |    194.443892 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                              |
| 843 |    575.956025 |    718.230925 | Mathieu Basille                                                                                                                                                |
| 844 |    469.635845 |    678.877596 | Gareth Monger                                                                                                                                                  |
| 845 |    225.113723 |    559.374165 | Andy Wilson                                                                                                                                                    |
| 846 |      9.044265 |    100.646400 | Steven Traver                                                                                                                                                  |
| 847 |     89.343975 |     90.119924 | Jagged Fang Designs                                                                                                                                            |
| 848 |    166.420533 |    167.674049 | NA                                                                                                                                                             |
| 849 |    923.064035 |    542.992557 | Michelle Site                                                                                                                                                  |
| 850 |    874.705541 |    459.646513 | Tasman Dixon                                                                                                                                                   |
| 851 |     40.536484 |    394.714622 | Alexandre Vong                                                                                                                                                 |
| 852 |    331.597924 |    318.927195 | Gareth Monger                                                                                                                                                  |
| 853 |    985.973250 |    696.564669 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                          |
| 854 |    963.821899 |    136.727572 | Fernando Carezzano                                                                                                                                             |
| 855 |    134.284068 |    143.706334 | Robert Hering                                                                                                                                                  |
| 856 |    307.080561 |    779.412168 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                |
| 857 |    204.909410 |    522.737438 | Young and Zhao (1972:figure 4), modified by Michael P. Taylor                                                                                                  |
| 858 |    199.686563 |    600.196717 | Cesar Julian                                                                                                                                                   |
| 859 |    249.557241 |    694.282453 | Steven Traver                                                                                                                                                  |
| 860 |    372.499225 |    667.025680 | Tyler Greenfield                                                                                                                                               |
| 861 |    615.544085 |    459.144863 | Lukasiniho                                                                                                                                                     |
| 862 |    521.433010 |    393.843237 | Collin Gross                                                                                                                                                   |
| 863 |    415.965040 |    358.725118 | Tauana J. Cunha                                                                                                                                                |
| 864 |    551.637145 |    496.050881 | Zimices                                                                                                                                                        |
| 865 |    725.810618 |    229.648894 | Gareth Monger                                                                                                                                                  |
| 866 |      8.352624 |    266.211254 | Jagged Fang Designs                                                                                                                                            |
| 867 |    209.256795 |    339.654289 | Lafage                                                                                                                                                         |
| 868 |    515.692256 |    717.490518 | V. Deepak                                                                                                                                                      |
| 869 |   1012.378277 |    278.823494 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                       |
| 870 |    259.311806 |    626.091300 | Margot Michaud                                                                                                                                                 |
| 871 |    641.430969 |    221.901549 | Scott Hartman                                                                                                                                                  |
| 872 |    806.815589 |    207.862606 | C. Camilo Julián-Caballero                                                                                                                                     |
| 873 |     89.681172 |    355.412969 | Cesar Julian                                                                                                                                                   |
| 874 |    773.548103 |     68.380957 | Ferran Sayol                                                                                                                                                   |
| 875 |    106.459562 |    353.773933 | Scott Hartman                                                                                                                                                  |
| 876 |    472.652547 |     65.840399 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 877 |    633.303298 |    248.602880 | Fernando Carezzano                                                                                                                                             |
| 878 |    433.373403 |    128.738803 | T. Michael Keesey                                                                                                                                              |
| 879 |    246.713524 |     43.055973 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                          |
| 880 |    468.677160 |    268.811868 | Steven Traver                                                                                                                                                  |
| 881 |    767.723527 |    565.082662 | Gareth Monger                                                                                                                                                  |
| 882 |    623.914885 |    224.166070 | Alexander Schmidt-Lebuhn                                                                                                                                       |
| 883 |    823.143512 |     59.647757 | T. Michael Keesey                                                                                                                                              |
| 884 |    186.501954 |    451.386503 | Gareth Monger                                                                                                                                                  |
| 885 |    866.391373 |    248.897272 | Zimices                                                                                                                                                        |
| 886 |    795.658186 |    113.978879 | Steven Traver                                                                                                                                                  |
| 887 |    509.729418 |    611.893094 | Vanessa Guerra                                                                                                                                                 |
| 888 |    450.975395 |    429.525302 | Kamil S. Jaron                                                                                                                                                 |
| 889 |      9.576135 |    624.962022 | Ferran Sayol                                                                                                                                                   |
| 890 |    479.305308 |    662.875150 | Margot Michaud                                                                                                                                                 |
| 891 |     71.480465 |    518.332502 | Jagged Fang Designs                                                                                                                                            |
| 892 |    274.618409 |    427.826114 | Noah Schlottman, photo from National Science Foundation - Turbellarian Taxonomic Database                                                                      |
| 893 |    324.729651 |    794.676972 | Claus Rebler                                                                                                                                                   |
| 894 |    478.601366 |    430.242192 | Gareth Monger                                                                                                                                                  |
| 895 |    371.780458 |      7.543070 | Tasman Dixon                                                                                                                                                   |
| 896 |    871.313262 |    372.017954 | NA                                                                                                                                                             |
| 897 |    828.813773 |    770.578846 | Smokeybjb, vectorized by Zimices                                                                                                                               |
| 898 |    556.263001 |    433.692172 | Steven Traver                                                                                                                                                  |
| 899 |    876.054009 |    234.260219 | Zimices                                                                                                                                                        |
| 900 |    402.058224 |    284.123258 | Beth Reinke                                                                                                                                                    |
| 901 |    106.472960 |    244.859371 | NA                                                                                                                                                             |
| 902 |    865.193109 |    242.916880 | Geoff Shaw                                                                                                                                                     |
| 903 |     10.554079 |    518.058034 | Gabriela Palomo-Munoz                                                                                                                                          |
| 904 |    978.678227 |    711.625722 | Sergio A. Muñoz-Gómez                                                                                                                                          |

    #> Your tweet has been posted!
