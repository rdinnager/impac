
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

Chris Jennings (Risiatto), Andy Wilson, Ferran Sayol, Dean Schnabel,
Andrew A. Farke, modified from original by Robert Bruce Horsfall, from
Scott 1912, Kent Elson Sorgon, Beth Reinke, Audrey Ely, Rebecca Groom,
Steven Traver, Zimices, Alexander Schmidt-Lebuhn, Matt Crook,
AnAgnosticGod (vectorized by T. Michael Keesey), Walter Vladimir, Margot
Michaud, Tasman Dixon, Jake Warner, Chris huh, , Markus A. Grohme,
Roberto Díaz Sibaja, Gareth Monger, Zimices / Julián Bayona, FunkMonk
\[Michael B.H.\] (modified by T. Michael Keesey), Andrew A. Farke, Scott
Hartman, Mariana Ruiz Villarreal, Caleb M. Brown, Darren Naish
(vectorize by T. Michael Keesey), Gabriela Palomo-Munoz, Kamil S. Jaron,
T. Michael Keesey (after Monika Betley), B. Duygu Özpolat, Nobu Tamura
(modified by T. Michael Keesey), T. Michael Keesey, Bruno Maggia, Alan
Manson (photo), John E. McCormack, Michael G. Harvey, Brant C.
Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T.
Michael Keesey, Meliponicultor Itaymbere, Jagged Fang Designs, Armin
Reindl, terngirl, Jaime Headden, Dmitry Bogdanov (vectorized by T.
Michael Keesey), Julia B McHugh, Iain Reid, Jack Mayer Wood, Mette
Aumala, Tyler Greenfield, Gustav Mützel, Tony Ayling (vectorized by
Milton Tan), Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti,
Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G.
Barraclough (vectorized by T. Michael Keesey), Tony Ayling (vectorized
by T. Michael Keesey), C. Camilo Julián-Caballero, Julio Garza, Mali’o
Kodis, image from the Smithsonian Institution, Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Nina Skinner, FunkMonk (Michael B. H.), Thibaut Brunet, Ignacio
Contreras, Inessa Voet, Erika Schumacher, nicubunu, S.Martini,
Cristopher Silva, Matt Martyniuk, Joris van der Ham (vectorized by T.
Michael Keesey), Pete Buchholz, Karla Martinez, Obsidian Soul
(vectorized by T. Michael Keesey), Melissa Broussard, T. Michael Keesey
(after Tillyard), Unknown (photo), John E. McCormack, Michael G. Harvey,
Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T.
Brumfield & T. Michael Keesey, Mathilde Cordellier, Jimmy Bernot,
Chuanixn Yu, Tracy A. Heath, Scott Reid, (unknown), Christoph Schomburg,
Trond R. Oskars, Haplochromis (vectorized by T. Michael Keesey), Maija
Karala, Birgit Lang, based on a photo by D. Sikes, Jose Carlos
Arenas-Monroy, Robert Bruce Horsfall, vectorized by Zimices, Michael
Scroggie, Michele M Tobias, Alex Slavenko, Robbie N. Cada (vectorized by
T. Michael Keesey), Sarah Werning, Mattia Menchetti, Nobu Tamura
(vectorized by T. Michael Keesey), Francesco Veronesi (vectorized by T.
Michael Keesey), SauropodomorphMonarch, Birgit Lang, SecretJellyMan,
Josep Marti Solans, T. Michael Keesey (after Kukalová), Tomas Willems
(vectorized by T. Michael Keesey), Lily Hughes, Matthew E. Clapham,
Michael P. Taylor, James R. Spotila and Ray Chatterji, Kanchi Nanjo,
Ernst Haeckel (vectorized by T. Michael Keesey), David Sim (photograph)
and T. Michael Keesey (vectorization), Lee Harding (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Gregor Bucher,
Max Farnworth, Abraão Leite, Charles R. Knight, vectorized by Zimices,
Maxime Dahirel, Sean McCann, Pranav Iyer (grey ideas), Tarique Sani
(photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth,
Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael
Keesey, Patrick Fisher (vectorized by T. Michael Keesey), Henry
Fairfield Osborn, vectorized by Zimices, Smokeybjb, Derek Bakken
(photograph) and T. Michael Keesey (vectorization), Lauren
Sumner-Rooney, Mali’o Kodis, photograph from
<http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>, Lukasiniho,
Ingo Braasch, CNZdenek, Emily Willoughby, Jessica Rick, Dinah Challen,
Mike Keesey (vectorization) and Vaibhavcho (photography), Frank Denota,
Harold N Eyster, Dein Freund der Baum (vectorized by T. Michael Keesey),
T. Michael Keesey (after C. De Muizon), Dexter R. Mardis, Matt Celeskey,
Christopher Chávez, Hans Hillewaert (vectorized by T. Michael Keesey),
Charles Doolittle Walcott (vectorized by T. Michael Keesey), Bruno C.
Vellutini, Michael B. H. (vectorized by T. Michael Keesey), Matt
Martyniuk (vectorized by T. Michael Keesey), Вальдимар (vectorized by T.
Michael Keesey), Agnello Picorelli, Xavier Giroux-Bougard, Carlos
Cano-Barbacil, L. Shyamal, Jiekun He, Greg Schechter (original photo),
Renato Santos (vector silhouette), Tauana J. Cunha, Juan Carlos Jerí,
Mateus Zica (modified by T. Michael Keesey), Michelle Site, Ieuan Jones,
Brad McFeeters (vectorized by T. Michael Keesey), xgirouxb, David Orr,
Mathieu Basille, Martin R. Smith, Mathieu Pélissié, Matt Dempsey,
Michael Day, Steven Coombs, Chase Brownstein, Tambja (vectorized by T.
Michael Keesey), Ekaterina Kopeykina (vectorized by T. Michael Keesey),
Felix Vaux, Jordan Mallon (vectorized by T. Michael Keesey), Matthew
Hooge (vectorized by T. Michael Keesey), Robert Gay, Jan A. Venter,
Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T.
Michael Keesey), Mali’o Kodis, photograph by P. Funch and R.M.
Kristensen, Shyamal, Rene Martin, Qiang Ou, Yan Wong, Steve
Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael
Keesey (vectorization), Berivan Temiz, Andrés Sánchez, NOAA Great Lakes
Environmental Research Laboratory (illustration) and Timothy J. Bartley
(silhouette), Terpsichores, Katie S. Collins, Jessica Anne Miller,
FunkMonk, Craig Dylke, Arthur Weasley (vectorized by T. Michael Keesey),
Yan Wong (vectorization) from 1873 illustration, Dori <dori@merr.info>
(source photo) and Nevit Dilmen, Philippe Janvier (vectorized by T.
Michael Keesey), Amanda Katzer, Lisa Byrne, Noah Schlottman, photo by
Carlos Sánchez-Ortiz, White Wolf, Antonov (vectorized by T. Michael
Keesey), Mathew Wedel, zoosnow, Wynston Cooper (photo) and Albertonykus
(silhouette), Ghedoghedo, vectorized by Zimices, Emma Kissling, Ellen
Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey), Sergio A.
Muñoz-Gómez, Nobu Tamura, vectorized by Zimices, T. Michael Keesey
(photo by Bc999 \[Black crow\]), André Karwath (vectorized by T. Michael
Keesey), Ville Koistinen (vectorized by T. Michael Keesey), Saguaro
Pictures (source photo) and T. Michael Keesey, Yan Wong from drawing by
Joseph Smit, . Original drawing by M. Antón, published in Montoya and
Morales 1984. Vectorized by O. Sanisidro, Conty (vectorized by T.
Michael Keesey), Crystal Maier, Taenadoman, Mo Hassan, Chris Hay,
Anthony Caravaggi, Blair Perry, Kimberly Haddrell, Didier Descouens
(vectorized by T. Michael Keesey), Chloé Schmidt, Ghedoghedo (vectorized
by T. Michael Keesey), Notafly (vectorized by T. Michael Keesey), Matt
Wilkins, Mark Witton, Ryan Cupo, Joanna Wolfe, Ewald Rübsamen, Mali’o
Kodis, image from Higgins and Kristensen, 1986, James I. Kirkland, Luis
Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P.
Wiersma (vectorized by T. Michael Keesey), Emily Jane McTavish, Caleb
Brown, Ricardo N. Martinez & Oscar A. Alcober, Jaime Headden (vectorized
by T. Michael Keesey), Stephen O’Connor (vectorized by T. Michael
Keesey), Robert Bruce Horsfall (vectorized by T. Michael Keesey), Noah
Schlottman, Neil Kelley, T. Michael Keesey (from a photograph by Frank
Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences), Kai R. Caspar, Ron
Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey
(vectorization), Mali’o Kodis, photograph by Ching
(<http://www.flickr.com/photos/36302473@N03/>), Richard Lampitt, Jeremy
Young / NHM (vectorization by Yan Wong), Keith Murdock (photo), John E.
McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford,
Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Emma Hughes,
Mark Hofstetter (vectorized by T. Michael Keesey), Jerry Oldenettel
(vectorized by T. Michael Keesey), Smokeybjb, vectorized by Zimices,
Cesar Julian, Michael Wolf (photo), Hans Hillewaert (editing), T.
Michael Keesey (vectorization), Karina Garcia, M Kolmann, Ray Simpson
(vectorized by T. Michael Keesey), Robert Hering, Leann Biancani, photo
by Kenneth Clifton, A. H. Baldwin (vectorized by T. Michael Keesey), Yan
Wong from photo by Denes Emoke, Dmitry Bogdanov, Jennifer Trimble, Scott
Hartman (vectorized by T. Michael Keesey), John Gould (vectorized by T.
Michael Keesey), Renata F. Martins, Danielle Alba, Almandine (vectorized
by T. Michael Keesey), Jonathan Wells, T. Michael Keesey (vectorization)
and Nadiatalent (photography), T. Tischler, Martin Kevil, Scott D.
Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A.
Forster, Joshua A. Smith, Alan L. Titus, Tess Linden, Falconaumanni and
T. Michael Keesey, Stacy Spensley (Modified), Jim Bendon (photography)
and T. Michael Keesey (vectorization), Lafage, Ludwik Gąsiorowski,
Lankester Edwin Ray (vectorized by T. Michael Keesey), Pearson Scott
Foresman (vectorized by T. Michael Keesey), Mattia Menchetti / Yan Wong,
Mali’o Kodis, photograph by Melissa Frey

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                                |
| --: | ------------: | ------------: | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    670.930040 |    607.717263 | Chris Jennings (Risiatto)                                                                                                                                             |
|   2 |     81.742081 |    529.009371 | Andy Wilson                                                                                                                                                           |
|   3 |    250.386132 |    673.543604 | Ferran Sayol                                                                                                                                                          |
|   4 |    523.977828 |    177.136564 | Dean Schnabel                                                                                                                                                         |
|   5 |    769.471703 |    370.861690 | Andrew A. Farke, modified from original by Robert Bruce Horsfall, from Scott 1912                                                                                     |
|   6 |     99.757938 |     25.487170 | Kent Elson Sorgon                                                                                                                                                     |
|   7 |    557.150999 |    711.176137 | Beth Reinke                                                                                                                                                           |
|   8 |    101.349700 |    360.767113 | Audrey Ely                                                                                                                                                            |
|   9 |    903.727749 |    158.516831 | Rebecca Groom                                                                                                                                                         |
|  10 |    243.747531 |    491.911453 | Steven Traver                                                                                                                                                         |
|  11 |    488.115993 |    604.049230 | Zimices                                                                                                                                                               |
|  12 |    496.175355 |    353.713402 | Andy Wilson                                                                                                                                                           |
|  13 |     88.204130 |    133.320353 | Alexander Schmidt-Lebuhn                                                                                                                                              |
|  14 |    945.032076 |    706.865091 | Matt Crook                                                                                                                                                            |
|  15 |    387.087215 |    676.240530 | AnAgnosticGod (vectorized by T. Michael Keesey)                                                                                                                       |
|  16 |    787.246813 |    254.274260 | Walter Vladimir                                                                                                                                                       |
|  17 |    615.095289 |    337.803166 | Margot Michaud                                                                                                                                                        |
|  18 |    451.006873 |    736.756237 | Tasman Dixon                                                                                                                                                          |
|  19 |    379.822659 |    376.969817 | Ferran Sayol                                                                                                                                                          |
|  20 |    348.841704 |    119.519823 | Matt Crook                                                                                                                                                            |
|  21 |    741.846568 |     49.650713 | Jake Warner                                                                                                                                                           |
|  22 |    278.181732 |    370.933986 | Steven Traver                                                                                                                                                         |
|  23 |    748.992468 |    464.714064 | Chris huh                                                                                                                                                             |
|  24 |    626.818115 |    498.073865 |                                                                                                                                                                       |
|  25 |    304.026362 |    757.921178 | Markus A. Grohme                                                                                                                                                      |
|  26 |    174.731139 |    567.621660 | Roberto Díaz Sibaja                                                                                                                                                   |
|  27 |    358.878281 |    501.079944 | Gareth Monger                                                                                                                                                         |
|  28 |     94.690811 |    702.000621 | NA                                                                                                                                                                    |
|  29 |    120.083527 |    238.510076 | Zimices / Julián Bayona                                                                                                                                               |
|  30 |    882.061577 |    778.691841 | FunkMonk \[Michael B.H.\] (modified by T. Michael Keesey)                                                                                                             |
|  31 |    593.369227 |     41.856224 | Andrew A. Farke                                                                                                                                                       |
|  32 |    796.183551 |    610.272311 | NA                                                                                                                                                                    |
|  33 |    218.922114 |     35.754689 | Scott Hartman                                                                                                                                                         |
|  34 |    925.352912 |    265.472871 | Mariana Ruiz Villarreal                                                                                                                                               |
|  35 |    616.948639 |    424.862446 | Margot Michaud                                                                                                                                                        |
|  36 |    955.351202 |    116.728703 | Caleb M. Brown                                                                                                                                                        |
|  37 |    856.292630 |    477.224934 | Matt Crook                                                                                                                                                            |
|  38 |    187.763225 |    101.210684 | Darren Naish (vectorize by T. Michael Keesey)                                                                                                                         |
|  39 |    102.855849 |    754.867270 | Zimices                                                                                                                                                               |
|  40 |    713.095657 |    106.268244 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  41 |    350.116059 |    266.539398 | Kamil S. Jaron                                                                                                                                                        |
|  42 |    914.067664 |    590.854621 | Andy Wilson                                                                                                                                                           |
|  43 |    690.671526 |    745.480043 | T. Michael Keesey (after Monika Betley)                                                                                                                               |
|  44 |    685.930402 |    192.265579 | B. Duygu Özpolat                                                                                                                                                      |
|  45 |    919.487804 |    377.155188 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
|  46 |    123.830846 |    637.302049 | T. Michael Keesey                                                                                                                                                     |
|  47 |    814.974535 |     20.938313 | Bruno Maggia                                                                                                                                                          |
|  48 |    871.616200 |    694.993682 | Jake Warner                                                                                                                                                           |
|  49 |    155.204546 |    393.009033 | Dean Schnabel                                                                                                                                                         |
|  50 |     62.890745 |    256.081672 | Gareth Monger                                                                                                                                                         |
|  51 |    442.732861 |    542.598689 | Matt Crook                                                                                                                                                            |
|  52 |    750.433499 |    686.641983 | Zimices                                                                                                                                                               |
|  53 |    460.775166 |    220.027765 | Scott Hartman                                                                                                                                                         |
|  54 |    849.872636 |    360.229098 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  55 |    732.862461 |    564.138994 | Meliponicultor Itaymbere                                                                                                                                              |
|  56 |    514.106186 |     92.127337 | Jagged Fang Designs                                                                                                                                                   |
|  57 |    600.659264 |    559.365343 | Scott Hartman                                                                                                                                                         |
|  58 |    978.095796 |    438.718300 | Armin Reindl                                                                                                                                                          |
|  59 |    290.126235 |    591.037213 | Chris Jennings (Risiatto)                                                                                                                                             |
|  60 |    780.232527 |    181.857195 | terngirl                                                                                                                                                              |
|  61 |    439.139557 |    638.893116 | Jaime Headden                                                                                                                                                         |
|  62 |    213.627586 |    293.878255 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  63 |    469.573582 |    778.865098 | Julia B McHugh                                                                                                                                                        |
|  64 |    262.890917 |    551.200592 | Chris huh                                                                                                                                                             |
|  65 |    841.298302 |    103.056906 | Chris huh                                                                                                                                                             |
|  66 |    886.654298 |    548.247139 | Matt Crook                                                                                                                                                            |
|  67 |    406.663004 |     11.604653 | Scott Hartman                                                                                                                                                         |
|  68 |    823.712185 |    297.013047 | Iain Reid                                                                                                                                                             |
|  69 |    229.362938 |    730.583605 | Jack Mayer Wood                                                                                                                                                       |
|  70 |    907.881114 |     57.454555 | NA                                                                                                                                                                    |
|  71 |    622.453397 |    738.177454 | Alan Manson (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
|  72 |     76.241375 |    427.944588 | Mette Aumala                                                                                                                                                          |
|  73 |      8.279563 |    560.482689 | Tyler Greenfield                                                                                                                                                      |
|  74 |    959.521541 |    322.123776 | Gustav Mützel                                                                                                                                                         |
|  75 |    550.624806 |    464.436574 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
|  76 |    755.908345 |    423.116976 | Jagged Fang Designs                                                                                                                                                   |
|  77 |    236.694282 |    222.843052 | Jagged Fang Designs                                                                                                                                                   |
|  78 |    645.694067 |    101.885231 | Jagged Fang Designs                                                                                                                                                   |
|  79 |    237.278135 |    772.390526 | Tony Ayling (vectorized by Milton Tan)                                                                                                                                |
|  80 |     40.658838 |     81.741788 | T. Michael Keesey                                                                                                                                                     |
|  81 |   1000.140734 |    174.921595 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
|  82 |    947.224604 |    146.130686 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
|  83 |    995.840063 |     90.636602 | C. Camilo Julián-Caballero                                                                                                                                            |
|  84 |    158.020672 |    178.681365 | Julio Garza                                                                                                                                                           |
|  85 |     29.982878 |    658.797873 | Gareth Monger                                                                                                                                                         |
|  86 |     32.731013 |    142.826591 | Mali’o Kodis, image from the Smithsonian Institution                                                                                                                  |
|  87 |    421.582111 |    397.101540 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
|  88 |    787.706469 |    324.240409 | Gabriela Palomo-Munoz                                                                                                                                                 |
|  89 |    265.980587 |    301.573112 | Jaime Headden                                                                                                                                                         |
|  90 |    433.384549 |    409.695122 | Matt Crook                                                                                                                                                            |
|  91 |    464.532703 |    687.624806 | Ferran Sayol                                                                                                                                                          |
|  92 |    793.408121 |    149.458959 | Gareth Monger                                                                                                                                                         |
|  93 |    965.934545 |     38.204134 | Markus A. Grohme                                                                                                                                                      |
|  94 |    296.991790 |    448.569352 | Nina Skinner                                                                                                                                                          |
|  95 |    575.128765 |    416.676928 | FunkMonk (Michael B. H.)                                                                                                                                              |
|  96 |    435.717819 |    388.868531 | Thibaut Brunet                                                                                                                                                        |
|  97 |    273.638381 |    503.585475 | Ignacio Contreras                                                                                                                                                     |
|  98 |    453.730795 |    205.873180 | Inessa Voet                                                                                                                                                           |
|  99 |    531.159805 |     10.875685 | Erika Schumacher                                                                                                                                                      |
| 100 |    461.624330 |    166.226434 | Dean Schnabel                                                                                                                                                         |
| 101 |    760.987146 |    702.152876 | nicubunu                                                                                                                                                              |
| 102 |   1002.246240 |    750.116093 | Markus A. Grohme                                                                                                                                                      |
| 103 |     77.370331 |    466.819862 | S.Martini                                                                                                                                                             |
| 104 |    156.141089 |    498.433193 | Matt Crook                                                                                                                                                            |
| 105 |    982.361443 |     68.756699 | Cristopher Silva                                                                                                                                                      |
| 106 |    987.897563 |    549.682114 | Matt Martyniuk                                                                                                                                                        |
| 107 |    435.501976 |    315.600948 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 108 |    222.983701 |    430.614078 | Steven Traver                                                                                                                                                         |
| 109 |    665.853122 |     34.795479 | NA                                                                                                                                                                    |
| 110 |    724.088813 |    386.203777 | Matt Crook                                                                                                                                                            |
| 111 |    965.540820 |    650.643198 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 112 |    112.750900 |    285.782653 | Scott Hartman                                                                                                                                                         |
| 113 |    664.707007 |    660.493024 | Margot Michaud                                                                                                                                                        |
| 114 |    531.092449 |    287.524595 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 115 |    179.585051 |    694.963591 | Matt Martyniuk                                                                                                                                                        |
| 116 |    676.907979 |    465.843407 | Joris van der Ham (vectorized by T. Michael Keesey)                                                                                                                   |
| 117 |    444.892675 |    351.116552 | Pete Buchholz                                                                                                                                                         |
| 118 |    712.575983 |    281.889091 | Margot Michaud                                                                                                                                                        |
| 119 |   1003.686941 |    769.544549 | Margot Michaud                                                                                                                                                        |
| 120 |    612.863869 |    217.653870 | Karla Martinez                                                                                                                                                        |
| 121 |    666.896552 |     71.992148 | Ignacio Contreras                                                                                                                                                     |
| 122 |    211.161305 |    184.431060 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |
| 123 |    147.581134 |    714.739872 | Melissa Broussard                                                                                                                                                     |
| 124 |    714.146053 |     19.436469 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 125 |     47.753356 |    673.288633 | Margot Michaud                                                                                                                                                        |
| 126 |    803.986876 |    220.965316 | Unknown (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey               |
| 127 |    431.104856 |     35.184659 | Mathilde Cordellier                                                                                                                                                   |
| 128 |    826.209167 |     69.926079 | terngirl                                                                                                                                                              |
| 129 |    355.315362 |    597.552950 | Jimmy Bernot                                                                                                                                                          |
| 130 |    708.692703 |    180.506715 | Chuanixn Yu                                                                                                                                                           |
| 131 |    178.902749 |    185.250993 | Tracy A. Heath                                                                                                                                                        |
| 132 |    698.840390 |    534.651915 | Ferran Sayol                                                                                                                                                          |
| 133 |    333.148374 |    514.682816 | Steven Traver                                                                                                                                                         |
| 134 |    535.419067 |    655.927164 | Scott Reid                                                                                                                                                            |
| 135 |    158.204725 |    131.243503 | Tasman Dixon                                                                                                                                                          |
| 136 |    475.356194 |     14.469951 | B. Duygu Özpolat                                                                                                                                                      |
| 137 |     47.979421 |    616.566884 | Andy Wilson                                                                                                                                                           |
| 138 |    331.233174 |    353.080515 | Matt Martyniuk                                                                                                                                                        |
| 139 |    649.795059 |    265.618856 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 140 |    592.129579 |    591.363000 | Steven Traver                                                                                                                                                         |
| 141 |    412.518655 |    494.202481 | Kamil S. Jaron                                                                                                                                                        |
| 142 |    252.347337 |    227.893614 | Gareth Monger                                                                                                                                                         |
| 143 |    315.701525 |    572.717736 | (unknown)                                                                                                                                                             |
| 144 |    385.323978 |    727.139663 | Christoph Schomburg                                                                                                                                                   |
| 145 |    942.387163 |     74.852348 | Nobu Tamura (modified by T. Michael Keesey)                                                                                                                           |
| 146 |    144.875685 |    264.142628 | B. Duygu Özpolat                                                                                                                                                      |
| 147 |    652.481346 |    791.466675 | Trond R. Oskars                                                                                                                                                       |
| 148 |    529.965933 |    732.834647 | Margot Michaud                                                                                                                                                        |
| 149 |    450.062071 |    133.162353 | Matt Crook                                                                                                                                                            |
| 150 |    975.304671 |    763.995066 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 151 |    955.945632 |    625.873191 | T. Michael Keesey                                                                                                                                                     |
| 152 |    338.724862 |    734.039560 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                                        |
| 153 |    498.961057 |    537.202147 | Maija Karala                                                                                                                                                          |
| 154 |    601.415515 |    191.915481 | Birgit Lang, based on a photo by D. Sikes                                                                                                                             |
| 155 |    553.524870 |    117.331517 | Gustav Mützel                                                                                                                                                         |
| 156 |    466.736394 |    654.256496 | Zimices                                                                                                                                                               |
| 157 |    283.796624 |    513.002043 | NA                                                                                                                                                                    |
| 158 |     44.108466 |    332.588924 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 159 |    188.395276 |    357.630962 | Robert Bruce Horsfall, vectorized by Zimices                                                                                                                          |
| 160 |    218.095287 |    385.309057 | NA                                                                                                                                                                    |
| 161 |    157.486217 |    782.147811 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 162 |     93.210607 |    296.337826 | Michael Scroggie                                                                                                                                                      |
| 163 |     71.616341 |    789.264024 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 164 |    712.510727 |    295.690512 | Margot Michaud                                                                                                                                                        |
| 165 |    790.653714 |    258.533396 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 166 |    542.069866 |    436.045310 | Michele M Tobias                                                                                                                                                      |
| 167 |    739.763458 |      2.655720 | Scott Hartman                                                                                                                                                         |
| 168 |    705.139155 |    493.050715 | Alex Slavenko                                                                                                                                                         |
| 169 |     35.161816 |     58.212146 | Robbie N. Cada (vectorized by T. Michael Keesey)                                                                                                                      |
| 170 |    178.112739 |    738.176156 | Gareth Monger                                                                                                                                                         |
| 171 |    671.995850 |    698.111990 | Zimices                                                                                                                                                               |
| 172 |    935.993349 |    411.233432 | Steven Traver                                                                                                                                                         |
| 173 |     72.543938 |     58.656689 | Sarah Werning                                                                                                                                                         |
| 174 |    509.155531 |    568.410858 | Sarah Werning                                                                                                                                                         |
| 175 |    713.360189 |    502.544783 | Mattia Menchetti                                                                                                                                                      |
| 176 |    376.716083 |    787.997203 | Erika Schumacher                                                                                                                                                      |
| 177 |    973.168416 |    170.394686 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 178 |     66.162642 |    592.566476 | Andy Wilson                                                                                                                                                           |
| 179 |    757.290739 |    654.402151 | Margot Michaud                                                                                                                                                        |
| 180 |    679.034905 |    352.530531 | B. Duygu Özpolat                                                                                                                                                      |
| 181 |    329.914173 |    456.993422 | Francesco Veronesi (vectorized by T. Michael Keesey)                                                                                                                  |
| 182 |    116.051793 |    192.306057 | Steven Traver                                                                                                                                                         |
| 183 |    768.503399 |    753.747555 | Margot Michaud                                                                                                                                                        |
| 184 |    944.562964 |    631.068813 | Andrew A. Farke                                                                                                                                                       |
| 185 |    940.940076 |    353.773011 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                                |
| 186 |    979.872521 |    160.043136 | SauropodomorphMonarch                                                                                                                                                 |
| 187 |      8.681206 |    386.624372 | Steven Traver                                                                                                                                                         |
| 188 |    362.230402 |    788.611569 | Steven Traver                                                                                                                                                         |
| 189 |    544.365907 |    766.789117 | Ferran Sayol                                                                                                                                                          |
| 190 |    822.507732 |    571.389816 | Gareth Monger                                                                                                                                                         |
| 191 |    625.360848 |    394.335351 | Birgit Lang                                                                                                                                                           |
| 192 |    761.223476 |    496.204499 | SecretJellyMan                                                                                                                                                        |
| 193 |    544.631609 |    535.978912 | Josep Marti Solans                                                                                                                                                    |
| 194 |    619.929357 |    528.047715 | T. Michael Keesey (after Kukalová)                                                                                                                                    |
| 195 |    138.418541 |     57.724823 | Chris huh                                                                                                                                                             |
| 196 |    687.997035 |    458.003388 | Scott Hartman                                                                                                                                                         |
| 197 |    777.147176 |    525.088530 | Tomas Willems (vectorized by T. Michael Keesey)                                                                                                                       |
| 198 |    119.302420 |    451.004486 | Lily Hughes                                                                                                                                                           |
| 199 |     62.402505 |    486.709993 | Chris huh                                                                                                                                                             |
| 200 |    896.384833 |    745.091967 | NA                                                                                                                                                                    |
| 201 |   1012.892979 |    642.711072 | Matthew E. Clapham                                                                                                                                                    |
| 202 |     85.022882 |    322.310865 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 203 |     30.241241 |    645.880890 | Michael P. Taylor                                                                                                                                                     |
| 204 |   1016.121220 |    258.040049 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 205 |    851.121813 |    279.942729 | Kanchi Nanjo                                                                                                                                                          |
| 206 |    139.337966 |    184.811194 | NA                                                                                                                                                                    |
| 207 |    452.131760 |     50.132857 | Cristopher Silva                                                                                                                                                      |
| 208 |    790.399230 |    552.175975 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 209 |    882.019360 |    321.325314 | Jimmy Bernot                                                                                                                                                          |
| 210 |    212.113448 |    674.691388 | Mathilde Cordellier                                                                                                                                                   |
| 211 |     28.178477 |    303.812442 | Ferran Sayol                                                                                                                                                          |
| 212 |    295.724544 |    243.572315 | Ferran Sayol                                                                                                                                                          |
| 213 |    299.314426 |     14.208731 | David Sim (photograph) and T. Michael Keesey (vectorization)                                                                                                          |
| 214 |    935.368121 |    606.372035 | Lee Harding (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey           |
| 215 |    951.190329 |    400.066905 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 216 |    135.373281 |    106.060649 | Gregor Bucher, Max Farnworth                                                                                                                                          |
| 217 |    385.535229 |    767.199956 | NA                                                                                                                                                                    |
| 218 |    960.507512 |    162.262049 | Matt Crook                                                                                                                                                            |
| 219 |    584.589498 |    783.314166 | Matt Crook                                                                                                                                                            |
| 220 |    940.404517 |    214.764210 | Andy Wilson                                                                                                                                                           |
| 221 |    707.521682 |    431.903051 | Abraão Leite                                                                                                                                                          |
| 222 |    275.033800 |     54.260163 | Gareth Monger                                                                                                                                                         |
| 223 |    489.443471 |    550.586227 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 224 |    170.896120 |    703.198098 | T. Michael Keesey                                                                                                                                                     |
| 225 |    514.508135 |    705.590152 | Charles R. Knight, vectorized by Zimices                                                                                                                              |
| 226 |    575.139984 |    592.597096 | NA                                                                                                                                                                    |
| 227 |     89.629766 |     74.476032 | Tracy A. Heath                                                                                                                                                        |
| 228 |   1010.297382 |    381.987747 | Maxime Dahirel                                                                                                                                                        |
| 229 |    305.370521 |    715.091967 | Chris huh                                                                                                                                                             |
| 230 |    102.564264 |    652.484490 | Scott Hartman                                                                                                                                                         |
| 231 |     34.107109 |    738.905237 | Sean McCann                                                                                                                                                           |
| 232 |    304.810846 |    516.366547 | Sarah Werning                                                                                                                                                         |
| 233 |    328.309366 |    647.654296 | Christoph Schomburg                                                                                                                                                   |
| 234 |    520.318828 |    756.119808 | Margot Michaud                                                                                                                                                        |
| 235 |    589.341049 |    481.711504 | Kamil S. Jaron                                                                                                                                                        |
| 236 |    783.357494 |    403.110769 | Zimices                                                                                                                                                               |
| 237 |    416.304793 |    456.163138 | Gareth Monger                                                                                                                                                         |
| 238 |    604.295013 |    644.426035 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 239 |     54.914411 |    644.562062 | Gareth Monger                                                                                                                                                         |
| 240 |    319.488283 |    493.082296 | Birgit Lang                                                                                                                                                           |
| 241 |    999.840812 |    279.118703 | Pranav Iyer (grey ideas)                                                                                                                                              |
| 242 |    847.083391 |    425.357443 | Jaime Headden                                                                                                                                                         |
| 243 |    469.720419 |     26.133261 | C. Camilo Julián-Caballero                                                                                                                                            |
| 244 |    506.050558 |    271.435908 | Beth Reinke                                                                                                                                                           |
| 245 |    160.424283 |    197.411524 | NA                                                                                                                                                                    |
| 246 |     66.996983 |    681.422862 | Markus A. Grohme                                                                                                                                                      |
| 247 |    495.601397 |     27.046864 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 248 |    347.057976 |    360.892766 | Jagged Fang Designs                                                                                                                                                   |
| 249 |    899.979984 |    453.977076 | Zimices                                                                                                                                                               |
| 250 |    401.205800 |    607.521358 | Patrick Fisher (vectorized by T. Michael Keesey)                                                                                                                      |
| 251 |    513.391801 |    529.787099 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                         |
| 252 |    905.472733 |    344.217286 | NA                                                                                                                                                                    |
| 253 |    182.632965 |    642.349290 | Smokeybjb                                                                                                                                                             |
| 254 |    516.625683 |    740.371205 | Mathilde Cordellier                                                                                                                                                   |
| 255 |    274.718626 |    274.823901 | NA                                                                                                                                                                    |
| 256 |    121.840407 |    363.631155 | Derek Bakken (photograph) and T. Michael Keesey (vectorization)                                                                                                       |
| 257 |    526.633182 |    519.521275 | Lauren Sumner-Rooney                                                                                                                                                  |
| 258 |    923.657204 |     27.408959 | Scott Hartman                                                                                                                                                         |
| 259 |    354.527228 |    334.018402 | Mali’o Kodis, photograph from <http://commons.wikimedia.org/wiki/File:Trichoplax.jpg>                                                                                 |
| 260 |    940.462070 |    472.229739 | Jaime Headden                                                                                                                                                         |
| 261 |    590.550242 |    298.365384 | Margot Michaud                                                                                                                                                        |
| 262 |    135.208297 |    159.435213 | Lukasiniho                                                                                                                                                            |
| 263 |    326.053657 |    788.509003 | Tarique Sani (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey          |
| 264 |    802.716785 |    537.173426 | Jaime Headden                                                                                                                                                         |
| 265 |      8.022734 |    195.774841 | Matt Crook                                                                                                                                                            |
| 266 |    126.048394 |    499.469525 | NA                                                                                                                                                                    |
| 267 |    513.097008 |    441.151834 | Ingo Braasch                                                                                                                                                          |
| 268 |    271.717069 |     71.291895 | Meliponicultor Itaymbere                                                                                                                                              |
| 269 |    212.903388 |    514.564721 | Chris huh                                                                                                                                                             |
| 270 |    907.370233 |     10.434784 | Matt Crook                                                                                                                                                            |
| 271 |     37.412094 |    535.937077 | CNZdenek                                                                                                                                                              |
| 272 |    764.453663 |    734.960054 | Emily Willoughby                                                                                                                                                      |
| 273 |    490.161559 |    691.101356 | Matt Crook                                                                                                                                                            |
| 274 |    540.997731 |    684.340544 | Ferran Sayol                                                                                                                                                          |
| 275 |    783.404702 |    140.137325 | Gareth Monger                                                                                                                                                         |
| 276 |    717.480696 |      5.340347 | Jessica Rick                                                                                                                                                          |
| 277 |    885.112620 |    429.728370 | Chris huh                                                                                                                                                             |
| 278 |    513.078387 |    485.515747 | Dinah Challen                                                                                                                                                         |
| 279 |    330.653525 |    716.090088 | Julio Garza                                                                                                                                                           |
| 280 |    652.229803 |    467.493512 | Zimices                                                                                                                                                               |
| 281 |    822.933537 |    276.659032 | Birgit Lang                                                                                                                                                           |
| 282 |    974.973960 |    509.166491 | NA                                                                                                                                                                    |
| 283 |    801.182603 |    204.702183 | Gareth Monger                                                                                                                                                         |
| 284 |    149.327238 |    145.993445 | Andy Wilson                                                                                                                                                           |
| 285 |    376.239477 |    633.455856 | Mike Keesey (vectorization) and Vaibhavcho (photography)                                                                                                              |
| 286 |    998.432270 |    693.124630 | Frank Denota                                                                                                                                                          |
| 287 |    323.295668 |    617.698103 | Harold N Eyster                                                                                                                                                       |
| 288 |   1002.316271 |    609.652947 | Ferran Sayol                                                                                                                                                          |
| 289 |    434.242266 |    279.112748 | Margot Michaud                                                                                                                                                        |
| 290 |    258.031893 |    268.411834 | Dein Freund der Baum (vectorized by T. Michael Keesey)                                                                                                                |
| 291 |    885.123133 |    738.755066 | Margot Michaud                                                                                                                                                        |
| 292 |    527.266330 |    319.311208 | T. Michael Keesey (after C. De Muizon)                                                                                                                                |
| 293 |    719.226438 |    130.403631 | Zimices                                                                                                                                                               |
| 294 |    185.792993 |    267.380869 | Dexter R. Mardis                                                                                                                                                      |
| 295 |    220.044692 |    369.483586 | Matt Celeskey                                                                                                                                                         |
| 296 |     22.947194 |    423.965794 | Christopher Chávez                                                                                                                                                    |
| 297 |    403.470146 |    324.905663 | Matt Crook                                                                                                                                                            |
| 298 |     13.112564 |    742.216492 | T. Michael Keesey                                                                                                                                                     |
| 299 |    707.098412 |    520.733112 | Tasman Dixon                                                                                                                                                          |
| 300 |    897.480097 |    227.931717 | Margot Michaud                                                                                                                                                        |
| 301 |    856.759778 |    540.590844 | Tasman Dixon                                                                                                                                                          |
| 302 |    598.822573 |    653.793910 | Maija Karala                                                                                                                                                          |
| 303 |    770.820643 |    441.013785 | T. Michael Keesey                                                                                                                                                     |
| 304 |     11.573459 |    270.633346 | Jimmy Bernot                                                                                                                                                          |
| 305 |    142.712255 |    481.211841 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 306 |    180.719600 |    619.833335 | Margot Michaud                                                                                                                                                        |
| 307 |    756.802308 |    211.066386 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 308 |    100.351554 |    389.881698 | Matt Crook                                                                                                                                                            |
| 309 |   1010.074520 |    231.429569 | Matt Crook                                                                                                                                                            |
| 310 |    441.965940 |    262.998792 | T. Michael Keesey                                                                                                                                                     |
| 311 |    510.599737 |    555.283858 | Tracy A. Heath                                                                                                                                                        |
| 312 |    887.531283 |    337.213808 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                           |
| 313 |    199.075977 |    797.742628 | Markus A. Grohme                                                                                                                                                      |
| 314 |    331.914790 |    254.319344 | Margot Michaud                                                                                                                                                        |
| 315 |    990.548513 |    653.048996 | Margot Michaud                                                                                                                                                        |
| 316 |     12.510767 |    766.807391 | Mette Aumala                                                                                                                                                          |
| 317 |      5.807798 |    673.234814 | Bruno C. Vellutini                                                                                                                                                    |
| 318 |    419.239837 |    363.571581 | Margot Michaud                                                                                                                                                        |
| 319 |    228.419594 |    504.696278 | Matt Crook                                                                                                                                                            |
| 320 |    657.819081 |    643.833262 | Caleb M. Brown                                                                                                                                                        |
| 321 |    529.057971 |     98.598557 | Mattia Menchetti                                                                                                                                                      |
| 322 |    293.244409 |    338.460055 | Ingo Braasch                                                                                                                                                          |
| 323 |    463.796525 |    105.352402 | Rebecca Groom                                                                                                                                                         |
| 324 |    252.524441 |    788.013516 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                                       |
| 325 |    890.447298 |    755.381718 | Zimices                                                                                                                                                               |
| 326 |    124.040304 |    699.551307 | Jagged Fang Designs                                                                                                                                                   |
| 327 |    266.559372 |      5.797651 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                                      |
| 328 |    993.342699 |    595.078370 | Steven Traver                                                                                                                                                         |
| 329 |    540.469055 |    575.108112 | Gareth Monger                                                                                                                                                         |
| 330 |     43.902404 |    358.619334 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 331 |     16.612438 |    485.208302 | Ferran Sayol                                                                                                                                                          |
| 332 |    963.810971 |     80.331791 | Gareth Monger                                                                                                                                                         |
| 333 |    743.518740 |    308.895720 | Вальдимар (vectorized by T. Michael Keesey)                                                                                                                           |
| 334 |    191.953978 |    152.784370 | Jagged Fang Designs                                                                                                                                                   |
| 335 |     21.904859 |     13.150759 | Agnello Picorelli                                                                                                                                                     |
| 336 |    764.341800 |     25.069099 | Matt Martyniuk                                                                                                                                                        |
| 337 |   1003.906281 |    525.064166 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 338 |    543.032084 |    408.782285 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 339 |    585.943845 |    606.572557 | Xavier Giroux-Bougard                                                                                                                                                 |
| 340 |    613.818351 |    663.584824 | Jagged Fang Designs                                                                                                                                                   |
| 341 |    140.165023 |    795.849943 | Zimices                                                                                                                                                               |
| 342 |    797.025357 |     88.587485 | Steven Traver                                                                                                                                                         |
| 343 |    993.719736 |    232.888798 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 344 |    605.130760 |    460.594105 | Andy Wilson                                                                                                                                                           |
| 345 |    864.333366 |    419.679197 | Carlos Cano-Barbacil                                                                                                                                                  |
| 346 |    147.123141 |    595.117494 | L. Shyamal                                                                                                                                                            |
| 347 |     47.230349 |    378.846879 | Matt Crook                                                                                                                                                            |
| 348 |    597.490280 |    687.095772 | Jiekun He                                                                                                                                                             |
| 349 |     26.015461 |    500.662277 | NA                                                                                                                                                                    |
| 350 |   1001.826819 |    455.499284 | Greg Schechter (original photo), Renato Santos (vector silhouette)                                                                                                    |
| 351 |    148.289005 |    528.536023 | Tauana J. Cunha                                                                                                                                                       |
| 352 |    704.175932 |    784.964500 | Chris huh                                                                                                                                                             |
| 353 |    487.075315 |    567.094355 | Juan Carlos Jerí                                                                                                                                                      |
| 354 |    631.709778 |     66.253002 | Chris huh                                                                                                                                                             |
| 355 |    730.886341 |    493.912736 | Mette Aumala                                                                                                                                                          |
| 356 |    186.332621 |    170.974694 | Mateus Zica (modified by T. Michael Keesey)                                                                                                                           |
| 357 |    590.502452 |    737.063026 | Michelle Site                                                                                                                                                         |
| 358 |    665.619478 |     12.717269 | Ieuan Jones                                                                                                                                                           |
| 359 |    619.618015 |    260.684415 | Mathilde Cordellier                                                                                                                                                   |
| 360 |    623.086319 |    138.546656 | Zimices                                                                                                                                                               |
| 361 |    420.860405 |    328.250780 | Meliponicultor Itaymbere                                                                                                                                              |
| 362 |    990.531380 |     46.675577 | Christoph Schomburg                                                                                                                                                   |
| 363 |    622.353698 |    179.126789 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 364 |    861.410563 |    390.234508 | Cristopher Silva                                                                                                                                                      |
| 365 |    832.388699 |    225.105256 | Zimices                                                                                                                                                               |
| 366 |    595.167225 |    140.176880 | Markus A. Grohme                                                                                                                                                      |
| 367 |    117.044850 |    293.278445 | T. Michael Keesey                                                                                                                                                     |
| 368 |    365.338304 |    714.642917 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 369 |    393.342687 |    531.560049 | Markus A. Grohme                                                                                                                                                      |
| 370 |    186.048276 |    250.679888 | Steven Traver                                                                                                                                                         |
| 371 |    660.371327 |    760.997398 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                                      |
| 372 |    535.578313 |    219.985000 | Margot Michaud                                                                                                                                                        |
| 373 |    916.382372 |    474.860362 | Xavier Giroux-Bougard                                                                                                                                                 |
| 374 |    667.103291 |    481.293702 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 375 |    277.951015 |    730.751919 | Jaime Headden                                                                                                                                                         |
| 376 |    687.883909 |    205.244392 | xgirouxb                                                                                                                                                              |
| 377 |    133.284980 |    679.417484 | Jagged Fang Designs                                                                                                                                                   |
| 378 |    502.884177 |    542.831381 | Jagged Fang Designs                                                                                                                                                   |
| 379 |    249.022282 |    743.054736 | Zimices                                                                                                                                                               |
| 380 |    478.703580 |    154.282763 | Ingo Braasch                                                                                                                                                          |
| 381 |    389.514288 |    296.129820 | David Orr                                                                                                                                                             |
| 382 |     21.050914 |    320.534862 | Mathieu Basille                                                                                                                                                       |
| 383 |    880.389031 |    404.722375 | Jagged Fang Designs                                                                                                                                                   |
| 384 |    184.217305 |    474.866698 | Martin R. Smith                                                                                                                                                       |
| 385 |    530.052209 |    508.353573 | Mathieu Pélissié                                                                                                                                                      |
| 386 |    172.246772 |    124.646443 | Matt Martyniuk                                                                                                                                                        |
| 387 |     49.982032 |    493.488138 | Matt Dempsey                                                                                                                                                          |
| 388 |     15.460908 |     43.404079 | Michael Day                                                                                                                                                           |
| 389 |    644.487956 |    577.495509 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 390 |    759.466886 |    287.045380 | Steven Coombs                                                                                                                                                         |
| 391 |     14.592307 |    244.760970 | Chase Brownstein                                                                                                                                                      |
| 392 |    953.630138 |    586.985182 | Tambja (vectorized by T. Michael Keesey)                                                                                                                              |
| 393 |    808.544183 |    567.944741 | Andy Wilson                                                                                                                                                           |
| 394 |    553.846607 |    250.150124 | Ekaterina Kopeykina (vectorized by T. Michael Keesey)                                                                                                                 |
| 395 |    630.859695 |     12.293245 | Tauana J. Cunha                                                                                                                                                       |
| 396 |    697.789494 |    333.023842 | Felix Vaux                                                                                                                                                            |
| 397 |    224.838814 |    408.565425 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 398 |      5.091542 |    229.146688 | Gareth Monger                                                                                                                                                         |
| 399 |    473.091679 |    705.726383 | NA                                                                                                                                                                    |
| 400 |    922.048641 |    209.109999 | Jordan Mallon (vectorized by T. Michael Keesey)                                                                                                                       |
| 401 |    296.146477 |    426.127385 | Matt Crook                                                                                                                                                            |
| 402 |   1005.179474 |    661.373182 | Matthew Hooge (vectorized by T. Michael Keesey)                                                                                                                       |
| 403 |    836.354813 |    122.305232 | Iain Reid                                                                                                                                                             |
| 404 |    825.869703 |     39.206062 | Robert Gay                                                                                                                                                            |
| 405 |    845.096100 |    195.749428 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                                   |
| 406 |   1007.879126 |    538.107904 | Gareth Monger                                                                                                                                                         |
| 407 |    251.837052 |    427.040074 | Mali’o Kodis, photograph by P. Funch and R.M. Kristensen                                                                                                              |
| 408 |    848.885816 |    215.788799 | Erika Schumacher                                                                                                                                                      |
| 409 |    194.034732 |    325.756564 | Shyamal                                                                                                                                                               |
| 410 |    196.190798 |    338.385671 | Margot Michaud                                                                                                                                                        |
| 411 |    211.546650 |    253.113223 | Steven Traver                                                                                                                                                         |
| 412 |    828.320135 |    318.216978 | Margot Michaud                                                                                                                                                        |
| 413 |    115.461870 |    582.528313 | Gareth Monger                                                                                                                                                         |
| 414 |    155.871200 |    765.893269 | Scott Hartman                                                                                                                                                         |
| 415 |    944.946140 |    337.070087 | Scott Hartman                                                                                                                                                         |
| 416 |    359.877918 |    639.864583 | T. Michael Keesey                                                                                                                                                     |
| 417 |    847.405544 |    360.422649 | Gareth Monger                                                                                                                                                         |
| 418 |    194.745123 |    742.154602 | Margot Michaud                                                                                                                                                        |
| 419 |    768.912531 |    630.524324 | Tracy A. Heath                                                                                                                                                        |
| 420 |    168.270272 |    691.067052 | Andrew A. Farke                                                                                                                                                       |
| 421 |    866.509804 |    738.093044 | Jaime Headden                                                                                                                                                         |
| 422 |    525.037227 |    303.046394 | terngirl                                                                                                                                                              |
| 423 |    791.234472 |    761.700824 | Sarah Werning                                                                                                                                                         |
| 424 |    992.597989 |    243.241771 | Zimices                                                                                                                                                               |
| 425 |    482.449137 |     60.627538 | Andy Wilson                                                                                                                                                           |
| 426 |    628.900859 |     22.071331 | Rene Martin                                                                                                                                                           |
| 427 |     22.777118 |    791.347390 | Qiang Ou                                                                                                                                                              |
| 428 |    551.180925 |    101.469024 | Matt Crook                                                                                                                                                            |
| 429 |     20.214069 |    381.855966 | Trond R. Oskars                                                                                                                                                       |
| 430 |    506.863393 |    670.974140 | Yan Wong                                                                                                                                                              |
| 431 |    124.622706 |    508.915877 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 432 |    211.468507 |    328.718819 | Steve Hillebrand/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                    |
| 433 |    168.510825 |    324.267129 | S.Martini                                                                                                                                                             |
| 434 |    616.367061 |     76.122988 | Lukasiniho                                                                                                                                                            |
| 435 |    697.320708 |    128.539484 | Beth Reinke                                                                                                                                                           |
| 436 |    847.312843 |    627.974688 | Ferran Sayol                                                                                                                                                          |
| 437 |    432.128007 |    442.671340 | Berivan Temiz                                                                                                                                                         |
| 438 |    681.595772 |    435.021994 | Andrés Sánchez                                                                                                                                                        |
| 439 |    156.345848 |    112.090560 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 440 |    113.379491 |    278.800670 | Carlos Cano-Barbacil                                                                                                                                                  |
| 441 |    522.510363 |    253.548422 | Kamil S. Jaron                                                                                                                                                        |
| 442 |    408.152309 |    343.574450 | Christoph Schomburg                                                                                                                                                   |
| 443 |    459.912993 |    188.962090 | Matt Crook                                                                                                                                                            |
| 444 |     21.463435 |    598.977992 | Jagged Fang Designs                                                                                                                                                   |
| 445 |    566.088425 |    603.735418 | Terpsichores                                                                                                                                                          |
| 446 |    682.902526 |    386.080677 | Katie S. Collins                                                                                                                                                      |
| 447 |    362.305422 |    536.261458 | T. Michael Keesey                                                                                                                                                     |
| 448 |    499.597975 |     15.037019 | Scott Hartman                                                                                                                                                         |
| 449 |     68.452528 |    499.121982 | Tauana J. Cunha                                                                                                                                                       |
| 450 |    836.884725 |    152.735456 | Mathieu Pélissié                                                                                                                                                      |
| 451 |    556.708834 |    776.056525 | Jessica Anne Miller                                                                                                                                                   |
| 452 |    515.148098 |    260.496889 | NA                                                                                                                                                                    |
| 453 |     25.035863 |    221.356973 | FunkMonk                                                                                                                                                              |
| 454 |    119.686930 |    664.818435 | Emily Willoughby                                                                                                                                                      |
| 455 |    470.852840 |     69.143559 | Craig Dylke                                                                                                                                                           |
| 456 |    680.445299 |    582.791672 | FunkMonk                                                                                                                                                              |
| 457 |    699.096208 |    351.501741 | Zimices                                                                                                                                                               |
| 458 |    445.251778 |     30.941995 | Arthur Weasley (vectorized by T. Michael Keesey)                                                                                                                      |
| 459 |    134.080725 |    284.801464 | Yan Wong (vectorization) from 1873 illustration                                                                                                                       |
| 460 |    425.331604 |    711.385766 | Matt Crook                                                                                                                                                            |
| 461 |    193.641577 |    754.456189 | FunkMonk                                                                                                                                                              |
| 462 |    540.866691 |    327.999132 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                                 |
| 463 |    630.095434 |    285.750092 | Margot Michaud                                                                                                                                                        |
| 464 |    396.475387 |    276.147003 | Philippe Janvier (vectorized by T. Michael Keesey)                                                                                                                    |
| 465 |    693.392289 |    603.711311 | Amanda Katzer                                                                                                                                                         |
| 466 |   1011.642432 |    764.003660 | Gareth Monger                                                                                                                                                         |
| 467 |    630.136721 |    460.743931 | Andrew A. Farke                                                                                                                                                       |
| 468 |    947.175397 |    418.394262 | Tyler Greenfield                                                                                                                                                      |
| 469 |    174.380918 |     57.778538 | Lisa Byrne                                                                                                                                                            |
| 470 |     19.297939 |    699.861544 | Zimices                                                                                                                                                               |
| 471 |    252.069624 |    627.451748 | Lukasiniho                                                                                                                                                            |
| 472 |    248.001902 |    683.429898 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 473 |    686.850190 |    265.806333 | Jagged Fang Designs                                                                                                                                                   |
| 474 |    629.773593 |    651.135510 | NA                                                                                                                                                                    |
| 475 |    505.024936 |    714.494795 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                                        |
| 476 |   1016.172384 |    553.964125 | White Wolf                                                                                                                                                            |
| 477 |     94.607026 |    610.872630 | Steven Traver                                                                                                                                                         |
| 478 |    143.284358 |      5.720436 | Steven Traver                                                                                                                                                         |
| 479 |    982.159905 |     16.738029 | Zimices                                                                                                                                                               |
| 480 |    340.181830 |    728.729157 | Chris huh                                                                                                                                                             |
| 481 |    289.843484 |    305.706320 | Steven Coombs                                                                                                                                                         |
| 482 |     14.627294 |    174.157969 | Gareth Monger                                                                                                                                                         |
| 483 |    994.798458 |    138.053436 | Jack Mayer Wood                                                                                                                                                       |
| 484 |    760.645891 |    790.323413 | Antonov (vectorized by T. Michael Keesey)                                                                                                                             |
| 485 |    661.505367 |    705.151122 | Mathew Wedel                                                                                                                                                          |
| 486 |    414.109656 |    379.861645 | Bruno C. Vellutini                                                                                                                                                    |
| 487 |    171.848238 |    750.149242 | Scott Hartman                                                                                                                                                         |
| 488 |    834.714124 |    113.831117 | NA                                                                                                                                                                    |
| 489 |    238.332562 |    420.787455 | Markus A. Grohme                                                                                                                                                      |
| 490 |    339.593395 |    335.700762 | Lily Hughes                                                                                                                                                           |
| 491 |    765.337091 |    508.656819 | Lukasiniho                                                                                                                                                            |
| 492 |    907.425369 |    430.563363 | Andy Wilson                                                                                                                                                           |
| 493 |     36.910358 |    179.639599 | C. Camilo Julián-Caballero                                                                                                                                            |
| 494 |    589.721372 |    174.597678 | Andy Wilson                                                                                                                                                           |
| 495 |    362.151398 |    566.279068 | Jessica Anne Miller                                                                                                                                                   |
| 496 |    527.582649 |    716.799736 | Zimices                                                                                                                                                               |
| 497 |    787.113049 |    304.832435 | Jagged Fang Designs                                                                                                                                                   |
| 498 |     10.521402 |    784.733599 | NA                                                                                                                                                                    |
| 499 |    921.826419 |    425.105714 | Margot Michaud                                                                                                                                                        |
| 500 |    547.896833 |    338.033569 | zoosnow                                                                                                                                                               |
| 501 |    693.511647 |    692.329085 | Agnello Picorelli                                                                                                                                                     |
| 502 |    430.578687 |    373.588473 | T. Michael Keesey                                                                                                                                                     |
| 503 |    652.145052 |    631.458771 | NA                                                                                                                                                                    |
| 504 |    292.192129 |      6.819344 | Matt Crook                                                                                                                                                            |
| 505 |    996.519425 |     26.991498 | T. Michael Keesey                                                                                                                                                     |
| 506 |    241.279628 |    172.227668 | Wynston Cooper (photo) and Albertonykus (silhouette)                                                                                                                  |
| 507 |     18.847290 |     20.909163 | Steven Traver                                                                                                                                                         |
| 508 |    947.725226 |    462.827652 | Felix Vaux                                                                                                                                                            |
| 509 |    322.932967 |    636.180172 | Scott Hartman                                                                                                                                                         |
| 510 |    240.370025 |    251.861802 | Ghedoghedo, vectorized by Zimices                                                                                                                                     |
| 511 |     12.019633 |    412.630057 | Tony Ayling (vectorized by T. Michael Keesey)                                                                                                                         |
| 512 |   1014.469242 |    181.121602 | Steven Traver                                                                                                                                                         |
| 513 |     33.120903 |    584.761827 | Emma Kissling                                                                                                                                                         |
| 514 |    870.828456 |    620.080311 | Steven Traver                                                                                                                                                         |
| 515 |    771.559689 |    771.929666 | Juan Carlos Jerí                                                                                                                                                      |
| 516 |    635.295565 |     31.010667 | Matt Crook                                                                                                                                                            |
| 517 |    524.193487 |    771.948286 | Scott Hartman                                                                                                                                                         |
| 518 |    313.713304 |    661.496654 | Margot Michaud                                                                                                                                                        |
| 519 |      8.503074 |    402.510532 | Kamil S. Jaron                                                                                                                                                        |
| 520 |    903.922406 |    758.868388 | Melissa Broussard                                                                                                                                                     |
| 521 |    971.564445 |    355.471782 | Andy Wilson                                                                                                                                                           |
| 522 |    829.197472 |    333.395492 | Zimices                                                                                                                                                               |
| 523 |    712.068346 |    682.369936 | xgirouxb                                                                                                                                                              |
| 524 |    943.052022 |     17.363824 | Gareth Monger                                                                                                                                                         |
| 525 |    465.098530 |    718.749978 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 526 |    433.542980 |    272.258559 | Margot Michaud                                                                                                                                                        |
| 527 |    833.425405 |     57.610939 | Matt Crook                                                                                                                                                            |
| 528 |    883.709542 |    219.828713 | Gareth Monger                                                                                                                                                         |
| 529 |    647.766363 |    163.673133 | T. Michael Keesey                                                                                                                                                     |
| 530 |    918.973771 |     92.218208 | Armin Reindl                                                                                                                                                          |
| 531 |    393.768695 |    756.058769 | Jessica Rick                                                                                                                                                          |
| 532 |    418.058968 |    267.675389 | Jagged Fang Designs                                                                                                                                                   |
| 533 |    836.150135 |    611.097894 | Matt Crook                                                                                                                                                            |
| 534 |    609.094182 |    123.529882 | Margot Michaud                                                                                                                                                        |
| 535 |     26.855172 |    571.953894 | Maija Karala                                                                                                                                                          |
| 536 |    808.194311 |    260.032476 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 537 |    395.506411 |    492.019265 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 538 |    840.657474 |    205.117818 | Michele M Tobias                                                                                                                                                      |
| 539 |    594.422711 |    194.236539 | Christoph Schomburg                                                                                                                                                   |
| 540 |    939.647103 |    535.400161 | Matthew E. Clapham                                                                                                                                                    |
| 541 |    770.122937 |    539.192549 | NA                                                                                                                                                                    |
| 542 |    521.157371 |     37.726500 | Markus A. Grohme                                                                                                                                                      |
| 543 |    250.816124 |     61.269220 | Chris huh                                                                                                                                                             |
| 544 |    360.950477 |    316.354024 | Jessica Anne Miller                                                                                                                                                   |
| 545 |    566.547440 |    269.947047 | Margot Michaud                                                                                                                                                        |
| 546 |    219.371154 |    704.568017 | Chris huh                                                                                                                                                             |
| 547 |    930.884141 |     36.283966 | Jiekun He                                                                                                                                                             |
| 548 |    969.576421 |    333.690971 | Sarah Werning                                                                                                                                                         |
| 549 |    330.980459 |     18.285988 | Andy Wilson                                                                                                                                                           |
| 550 |    231.790811 |     44.666242 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 551 |    433.646168 |    298.761687 | Michelle Site                                                                                                                                                         |
| 552 |    234.194061 |    266.698452 | Gareth Monger                                                                                                                                                         |
| 553 |    416.790264 |    246.342162 | Margot Michaud                                                                                                                                                        |
| 554 |    805.783916 |    792.895681 | Zimices                                                                                                                                                               |
| 555 |     99.958831 |    311.512255 | Zimices                                                                                                                                                               |
| 556 |    486.554143 |    138.088232 | Sarah Werning                                                                                                                                                         |
| 557 |    702.498785 |    315.066429 | André Karwath (vectorized by T. Michael Keesey)                                                                                                                       |
| 558 |    490.211463 |     47.792813 | Steven Traver                                                                                                                                                         |
| 559 |    784.825891 |    418.900911 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 560 |     37.919485 |    158.764483 | Jagged Fang Designs                                                                                                                                                   |
| 561 |    732.392825 |    118.590670 | Gareth Monger                                                                                                                                                         |
| 562 |    377.785888 |    448.705816 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 563 |    286.583882 |    678.231966 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 564 |    533.270148 |    238.387983 | Ville Koistinen (vectorized by T. Michael Keesey)                                                                                                                     |
| 565 |   1008.328041 |     59.920696 | Saguaro Pictures (source photo) and T. Michael Keesey                                                                                                                 |
| 566 |   1014.042314 |    687.785873 | Yan Wong from drawing by Joseph Smit                                                                                                                                  |
| 567 |    901.528991 |     29.107771 | . Original drawing by M. Antón, published in Montoya and Morales 1984. Vectorized by O. Sanisidro                                                                     |
| 568 |    721.080565 |    777.816014 | Tasman Dixon                                                                                                                                                          |
| 569 |   1012.376842 |    339.677174 | Sarah Werning                                                                                                                                                         |
| 570 |    808.418338 |     85.714049 | T. Michael Keesey                                                                                                                                                     |
| 571 |    827.978742 |    681.090776 | Gareth Monger                                                                                                                                                         |
| 572 |    390.824740 |    464.262332 | Conty (vectorized by T. Michael Keesey)                                                                                                                               |
| 573 |    798.604189 |    736.325802 | Margot Michaud                                                                                                                                                        |
| 574 |    228.324055 |    332.650198 | Margot Michaud                                                                                                                                                        |
| 575 |    766.205961 |    582.939513 | Matt Crook                                                                                                                                                            |
| 576 |    670.125629 |    151.979329 | Crystal Maier                                                                                                                                                         |
| 577 |    412.512060 |    611.396327 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 578 |     33.052342 |    760.634685 | Taenadoman                                                                                                                                                            |
| 579 |    490.295482 |    556.994883 | Gareth Monger                                                                                                                                                         |
| 580 |    112.595300 |    791.133858 | Mo Hassan                                                                                                                                                             |
| 581 |    924.589133 |    561.545882 | Felix Vaux                                                                                                                                                            |
| 582 |    419.375671 |    517.068009 | Margot Michaud                                                                                                                                                        |
| 583 |    984.164285 |    344.722813 | Jaime Headden                                                                                                                                                         |
| 584 |    891.340294 |    216.290755 | Chris Hay                                                                                                                                                             |
| 585 |    522.018352 |    539.381090 | Anthony Caravaggi                                                                                                                                                     |
| 586 |     24.584426 |    406.742864 | Maija Karala                                                                                                                                                          |
| 587 |    448.787603 |    189.247731 | Blair Perry                                                                                                                                                           |
| 588 |    709.932473 |    245.659543 | Kimberly Haddrell                                                                                                                                                     |
| 589 |    368.616232 |    281.276923 | Christoph Schomburg                                                                                                                                                   |
| 590 |    244.496345 |     73.995515 | NA                                                                                                                                                                    |
| 591 |    558.390900 |     58.618514 | T. Michael Keesey                                                                                                                                                     |
| 592 |    680.071558 |    275.608322 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 593 |    163.152510 |    464.692891 | Andy Wilson                                                                                                                                                           |
| 594 |    996.297849 |    676.199024 | Andy Wilson                                                                                                                                                           |
| 595 |     87.185432 |     47.853448 | Scott Hartman                                                                                                                                                         |
| 596 |    520.160163 |    416.415126 | Jagged Fang Designs                                                                                                                                                   |
| 597 |    523.181758 |    337.023884 | Chloé Schmidt                                                                                                                                                         |
| 598 |    228.647607 |    635.668969 | Scott Hartman                                                                                                                                                         |
| 599 |     14.073660 |     94.361221 | Tracy A. Heath                                                                                                                                                        |
| 600 |    639.331258 |    545.235469 | Zimices                                                                                                                                                               |
| 601 |    114.104075 |    595.359933 | NA                                                                                                                                                                    |
| 602 |    418.220059 |    306.145633 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 603 |    749.160793 |    488.885199 | Juan Carlos Jerí                                                                                                                                                      |
| 604 |    424.141407 |    187.784413 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                          |
| 605 |    167.228413 |     15.385559 | Harold N Eyster                                                                                                                                                       |
| 606 |     27.669282 |    747.297599 | Jack Mayer Wood                                                                                                                                                       |
| 607 |     52.060825 |    320.406516 | B. Duygu Özpolat                                                                                                                                                      |
| 608 |     43.821350 |    646.973953 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 609 |    631.672866 |    473.308363 | Matt Wilkins                                                                                                                                                          |
| 610 |    826.288058 |    146.892547 | NA                                                                                                                                                                    |
| 611 |    541.780491 |    268.020727 | Steven Traver                                                                                                                                                         |
| 612 |    223.585421 |    694.436979 | Jagged Fang Designs                                                                                                                                                   |
| 613 |    577.651150 |    610.543307 | Mark Witton                                                                                                                                                           |
| 614 |     38.724866 |    233.703164 | Gareth Monger                                                                                                                                                         |
| 615 |     75.022148 |    720.827365 | Ryan Cupo                                                                                                                                                             |
| 616 |    662.468449 |    455.443621 | terngirl                                                                                                                                                              |
| 617 |    813.715878 |    146.452508 | Margot Michaud                                                                                                                                                        |
| 618 |    847.826248 |    263.211201 | Steven Coombs                                                                                                                                                         |
| 619 |    270.108227 |    349.015656 | Joanna Wolfe                                                                                                                                                          |
| 620 |    859.742007 |    745.986376 | Matt Crook                                                                                                                                                            |
| 621 |   1020.417837 |    268.769660 | T. Michael Keesey                                                                                                                                                     |
| 622 |      8.933788 |    372.731680 | Zimices                                                                                                                                                               |
| 623 |    410.815988 |    435.394552 | Ewald Rübsamen                                                                                                                                                        |
| 624 |     31.607879 |    370.208478 | NA                                                                                                                                                                    |
| 625 |    922.086451 |    452.702842 | Mali’o Kodis, image from Higgins and Kristensen, 1986                                                                                                                 |
| 626 |    825.100118 |    753.773450 | Ferran Sayol                                                                                                                                                          |
| 627 |    519.088016 |    112.597456 | Matt Crook                                                                                                                                                            |
| 628 |    351.163176 |    711.987704 | James I. Kirkland, Luis Alcalá, Mark A. Loewen, Eduardo Espílez, Luis Mampel, and Jelle P. Wiersma (vectorized by T. Michael Keesey)                                  |
| 629 |     29.356929 |    269.863590 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 630 |    293.460726 |    792.139969 | Scott Hartman                                                                                                                                                         |
| 631 |    111.353492 |    703.223518 | CNZdenek                                                                                                                                                              |
| 632 |    444.618704 |    121.337679 | Margot Michaud                                                                                                                                                        |
| 633 |    712.895951 |    710.733880 | Beth Reinke                                                                                                                                                           |
| 634 |    585.195304 |    254.003181 | Birgit Lang                                                                                                                                                           |
| 635 |    681.928167 |    295.482130 | Birgit Lang                                                                                                                                                           |
| 636 |    775.927373 |    103.706297 | Gareth Monger                                                                                                                                                         |
| 637 |    268.736931 |     29.764726 | Sarah Werning                                                                                                                                                         |
| 638 |    771.088391 |    600.379855 | Lukasiniho                                                                                                                                                            |
| 639 |    296.439619 |    272.523067 | NA                                                                                                                                                                    |
| 640 |     20.573200 |    628.955700 | Emily Jane McTavish                                                                                                                                                   |
| 641 |    329.719269 |    490.798522 | Scott Hartman                                                                                                                                                         |
| 642 |    305.638501 |    724.836439 | Michael Scroggie                                                                                                                                                      |
| 643 |    285.965535 |    454.218682 | Caleb Brown                                                                                                                                                           |
| 644 |   1002.775369 |    115.882966 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 645 |    987.940484 |    646.907915 | Ricardo N. Martinez & Oscar A. Alcober                                                                                                                                |
| 646 |    899.531233 |    640.032606 | Kamil S. Jaron                                                                                                                                                        |
| 647 |    716.229834 |     29.263156 | Margot Michaud                                                                                                                                                        |
| 648 |    609.525141 |    578.553480 | Berivan Temiz                                                                                                                                                         |
| 649 |    519.166426 |    663.265351 | Margot Michaud                                                                                                                                                        |
| 650 |    685.193644 |    413.385850 | Gareth Monger                                                                                                                                                         |
| 651 |    320.319009 |    445.763574 | Dexter R. Mardis                                                                                                                                                      |
| 652 |    982.454164 |    640.061610 | Scott Hartman                                                                                                                                                         |
| 653 |    336.501103 |    561.200312 | Zimices                                                                                                                                                               |
| 654 |    929.276574 |    140.937947 | Chris huh                                                                                                                                                             |
| 655 |    330.816936 |    695.146220 | Tauana J. Cunha                                                                                                                                                       |
| 656 |     87.100336 |    374.537927 | NA                                                                                                                                                                    |
| 657 |    185.967025 |    661.639086 | Jaime Headden (vectorized by T. Michael Keesey)                                                                                                                       |
| 658 |    932.385477 |    489.107171 | Tracy A. Heath                                                                                                                                                        |
| 659 |    538.327420 |     60.608473 | Mathilde Cordellier                                                                                                                                                   |
| 660 |    878.073868 |    243.882191 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 661 |   1003.622124 |    125.810600 | Stephen O’Connor (vectorized by T. Michael Keesey)                                                                                                                    |
| 662 |    129.925439 |    724.593015 | Robert Bruce Horsfall (vectorized by T. Michael Keesey)                                                                                                               |
| 663 |    702.970040 |    142.692164 | Christoph Schomburg                                                                                                                                                   |
| 664 |    761.057593 |     75.617314 | Tracy A. Heath                                                                                                                                                        |
| 665 |   1004.615866 |    510.349271 | Margot Michaud                                                                                                                                                        |
| 666 |    830.826230 |    214.896662 | Ferran Sayol                                                                                                                                                          |
| 667 |     20.352493 |    114.308270 | NA                                                                                                                                                                    |
| 668 |    400.962499 |    446.485115 | NA                                                                                                                                                                    |
| 669 |    321.342352 |    434.622676 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 670 |     88.891949 |    660.358179 | Margot Michaud                                                                                                                                                        |
| 671 |    649.960398 |    127.658784 | Matt Crook                                                                                                                                                            |
| 672 |    950.465941 |    424.448322 | Tasman Dixon                                                                                                                                                          |
| 673 |    871.431537 |    189.643183 | Noah Schlottman                                                                                                                                                       |
| 674 |    727.613238 |    140.080807 | Zimices                                                                                                                                                               |
| 675 |    658.992875 |    321.120583 | Matt Martyniuk                                                                                                                                                        |
| 676 |     40.136252 |    512.277830 | Zimices                                                                                                                                                               |
| 677 |    830.733495 |    547.489705 | SauropodomorphMonarch                                                                                                                                                 |
| 678 |    524.407778 |    494.418386 | Andy Wilson                                                                                                                                                           |
| 679 |    711.699215 |    697.617027 | Matt Crook                                                                                                                                                            |
| 680 |    413.717822 |    222.205483 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                                     |
| 681 |     90.486021 |    680.370256 | Ignacio Contreras                                                                                                                                                     |
| 682 |    666.194835 |    583.142334 | Andy Wilson                                                                                                                                                           |
| 683 |    648.865063 |    716.869404 | Neil Kelley                                                                                                                                                           |
| 684 |     33.298696 |    393.626348 | James R. Spotila and Ray Chatterji                                                                                                                                    |
| 685 |    670.984323 |    239.613721 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                                     |
| 686 |    124.981557 |    525.037659 | T. Michael Keesey (after Tillyard)                                                                                                                                    |
| 687 |    343.452145 |    780.726530 | Kai R. Caspar                                                                                                                                                         |
| 688 |    289.548708 |     34.205806 | Margot Michaud                                                                                                                                                        |
| 689 |    684.098856 |    423.336610 | Margot Michaud                                                                                                                                                        |
| 690 |    893.677977 |    625.341238 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                                    |
| 691 |    146.666458 |    336.887676 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 692 |    715.385975 |    257.542514 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 693 |    279.916159 |    430.707556 | Ron Holmes/U. S. Fish and Wildlife Service (source photo), T. Michael Keesey (vectorization)                                                                          |
| 694 |    209.800160 |    506.135439 | Mali’o Kodis, photograph by Ching (<http://www.flickr.com/photos/36302473@N03/>)                                                                                      |
| 695 |    996.016721 |    142.143920 | Markus A. Grohme                                                                                                                                                      |
| 696 |     50.223851 |    521.648402 | Jagged Fang Designs                                                                                                                                                   |
| 697 |    623.780109 |    633.780526 | Andy Wilson                                                                                                                                                           |
| 698 |    583.154247 |    676.175554 | Caleb Brown                                                                                                                                                           |
| 699 |    290.571066 |    496.678581 | Jake Warner                                                                                                                                                           |
| 700 |    640.605252 |    792.221057 | Katie S. Collins                                                                                                                                                      |
| 701 |     88.258390 |    388.831678 | Gareth Monger                                                                                                                                                         |
| 702 |     53.010714 |    607.051242 | Maija Karala                                                                                                                                                          |
| 703 |    528.138457 |    400.769594 | Matt Crook                                                                                                                                                            |
| 704 |    628.219233 |    670.588055 | Michelle Site                                                                                                                                                         |
| 705 |     32.652946 |    721.896188 | Margot Michaud                                                                                                                                                        |
| 706 |    679.100500 |    594.381493 | Alex Slavenko                                                                                                                                                         |
| 707 |    699.821861 |     73.568821 | Steven Traver                                                                                                                                                         |
| 708 |    491.548327 |    707.557228 | Richard Lampitt, Jeremy Young / NHM (vectorization by Yan Wong)                                                                                                       |
| 709 |     48.728849 |    349.818472 | Ignacio Contreras                                                                                                                                                     |
| 710 |    984.874278 |    626.132257 | Melissa Broussard                                                                                                                                                     |
| 711 |    998.955633 |    299.090253 | NA                                                                                                                                                                    |
| 712 |    821.805311 |    596.186005 | Keith Murdock (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey         |
| 713 |    973.747888 |    118.602560 | Zimices                                                                                                                                                               |
| 714 |    759.207123 |    330.001780 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 715 |     71.823714 |     42.437926 | Zimices                                                                                                                                                               |
| 716 |    735.162337 |    129.347042 | C. Camilo Julián-Caballero                                                                                                                                            |
| 717 |    581.495557 |    335.570755 | Markus A. Grohme                                                                                                                                                      |
| 718 |     28.791422 |    346.154260 | Emma Hughes                                                                                                                                                           |
| 719 |   1006.908135 |     22.156324 | NA                                                                                                                                                                    |
| 720 |    602.575939 |      8.729294 | NA                                                                                                                                                                    |
| 721 |    523.171012 |    637.229288 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 722 |    921.086237 |    329.365110 | Neil Kelley                                                                                                                                                           |
| 723 |    952.603058 |    391.073799 | Melissa Broussard                                                                                                                                                     |
| 724 |    655.354594 |     58.819303 | Mark Hofstetter (vectorized by T. Michael Keesey)                                                                                                                     |
| 725 |    779.892865 |     82.563042 | Tracy A. Heath                                                                                                                                                        |
| 726 |    394.386947 |    259.827548 | Jaime Headden                                                                                                                                                         |
| 727 |     12.754155 |    300.865943 | Matt Crook                                                                                                                                                            |
| 728 |    634.760320 |    771.835817 | Notafly (vectorized by T. Michael Keesey)                                                                                                                             |
| 729 |    984.655578 |     35.850369 | Iain Reid                                                                                                                                                             |
| 730 |    671.632763 |     59.265735 | Jiekun He                                                                                                                                                             |
| 731 |    168.746912 |    713.859302 | Jerry Oldenettel (vectorized by T. Michael Keesey)                                                                                                                    |
| 732 |    767.840785 |    205.472139 | Gareth Monger                                                                                                                                                         |
| 733 |    349.846744 |    395.347561 | Smokeybjb, vectorized by Zimices                                                                                                                                      |
| 734 |    873.315950 |     35.615384 | Chris huh                                                                                                                                                             |
| 735 |    946.989303 |    437.298072 | Gareth Monger                                                                                                                                                         |
| 736 |   1005.256454 |    790.192876 | Chris huh                                                                                                                                                             |
| 737 |    136.462068 |    512.939148 | Diego Fontaneto, Elisabeth A. Herniou, Chiara Boschetti, Manuela Caprioli, Giulio Melone, Claudia Ricci, and Timothy G. Barraclough (vectorized by T. Michael Keesey) |
| 738 |    333.895979 |    439.372006 | Melissa Broussard                                                                                                                                                     |
| 739 |    439.568977 |    510.508399 | Matt Crook                                                                                                                                                            |
| 740 |     71.964199 |     71.803545 | Zimices                                                                                                                                                               |
| 741 |    139.069062 |    650.897422 | Michael Scroggie                                                                                                                                                      |
| 742 |    778.806478 |    492.068895 | Steven Traver                                                                                                                                                         |
| 743 |    499.802753 |     63.515690 | Scott Hartman                                                                                                                                                         |
| 744 |    415.149261 |    287.094265 | Tasman Dixon                                                                                                                                                          |
| 745 |    610.572408 |    159.361114 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 746 |    241.333791 |    316.149220 | T. Michael Keesey                                                                                                                                                     |
| 747 |    102.982169 |     48.609103 | Scott Reid                                                                                                                                                            |
| 748 |    244.036700 |    393.460643 | Kamil S. Jaron                                                                                                                                                        |
| 749 |    575.119532 |    791.122331 | Cesar Julian                                                                                                                                                          |
| 750 |    391.057132 |    743.190689 | Julio Garza                                                                                                                                                           |
| 751 |    280.255395 |    267.616269 | Chris huh                                                                                                                                                             |
| 752 |    728.801427 |    303.046429 | Mathilde Cordellier                                                                                                                                                   |
| 753 |    365.252276 |    618.276094 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 754 |    488.263862 |    740.103639 | Jagged Fang Designs                                                                                                                                                   |
| 755 |    918.286472 |    669.240128 | Zimices                                                                                                                                                               |
| 756 |    553.525719 |    356.100360 | Scott Hartman                                                                                                                                                         |
| 757 |    697.983097 |    273.392618 | Margot Michaud                                                                                                                                                        |
| 758 |     40.801803 |    759.493386 | SauropodomorphMonarch                                                                                                                                                 |
| 759 |     45.381283 |    788.160474 | Gareth Monger                                                                                                                                                         |
| 760 |    574.051713 |    681.837847 | Michael Wolf (photo), Hans Hillewaert (editing), T. Michael Keesey (vectorization)                                                                                    |
| 761 |     64.621139 |    316.577534 | NA                                                                                                                                                                    |
| 762 |    380.362870 |    690.335065 | Yan Wong                                                                                                                                                              |
| 763 |    188.348284 |    178.232069 | Alex Slavenko                                                                                                                                                         |
| 764 |    627.483048 |    446.614622 | Karina Garcia                                                                                                                                                         |
| 765 |    840.161680 |    754.186897 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 766 |    886.529712 |    416.953509 | NA                                                                                                                                                                    |
| 767 |    256.250890 |    732.634470 | NA                                                                                                                                                                    |
| 768 |    535.153997 |    699.077693 | Chloé Schmidt                                                                                                                                                         |
| 769 |    347.162452 |    573.924490 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 770 |    931.283059 |     97.230041 | M Kolmann                                                                                                                                                             |
| 771 |    465.598122 |    481.320607 | Katie S. Collins                                                                                                                                                      |
| 772 |    326.120257 |    581.802993 | T. Michael Keesey                                                                                                                                                     |
| 773 |    742.630852 |     14.993270 | Dean Schnabel                                                                                                                                                         |
| 774 |    157.329249 |     52.498720 | Kai R. Caspar                                                                                                                                                         |
| 775 |    847.201336 |    227.266654 | NA                                                                                                                                                                    |
| 776 |    680.087097 |    512.297127 | Andy Wilson                                                                                                                                                           |
| 777 |    787.353885 |     98.854630 | T. Michael Keesey                                                                                                                                                     |
| 778 |   1008.592986 |    216.458331 | Rebecca Groom                                                                                                                                                         |
| 779 |    930.633486 |    599.231656 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 780 |    674.893791 |     85.588010 | Markus A. Grohme                                                                                                                                                      |
| 781 |    742.583628 |    794.562030 | Sarah Werning                                                                                                                                                         |
| 782 |    291.753714 |    797.681796 | Steven Traver                                                                                                                                                         |
| 783 |    629.913612 |    250.170443 | Tyler Greenfield                                                                                                                                                      |
| 784 |    157.330854 |    730.807538 | Mette Aumala                                                                                                                                                          |
| 785 |    377.329913 |    300.402324 | Zimices                                                                                                                                                               |
| 786 |    503.931459 |     45.370166 | Ernst Haeckel (vectorized by T. Michael Keesey)                                                                                                                       |
| 787 |     40.509521 |    428.118373 | Ray Simpson (vectorized by T. Michael Keesey)                                                                                                                         |
| 788 |    219.121376 |    600.764840 | Margot Michaud                                                                                                                                                        |
| 789 |    331.465838 |      6.866188 | Gareth Monger                                                                                                                                                         |
| 790 |    194.690353 |    505.559383 | T. Michael Keesey                                                                                                                                                     |
| 791 |   1006.280037 |    710.573691 | Matt Crook                                                                                                                                                            |
| 792 |    514.429184 |    324.182009 | Dean Schnabel                                                                                                                                                         |
| 793 |    821.780020 |     76.722665 | Robert Hering                                                                                                                                                         |
| 794 |    550.885786 |    395.277282 | Leann Biancani, photo by Kenneth Clifton                                                                                                                              |
| 795 |    481.992626 |    666.967175 | Zimices                                                                                                                                                               |
| 796 |    944.795758 |    305.533591 | Matt Crook                                                                                                                                                            |
| 797 |    309.677092 |    708.883147 | Mattia Menchetti                                                                                                                                                      |
| 798 |    171.802879 |    304.171479 | Zimices                                                                                                                                                               |
| 799 |    404.317740 |    701.753675 | Zimices                                                                                                                                                               |
| 800 |    906.948134 |    299.494215 | Tauana J. Cunha                                                                                                                                                       |
| 801 |    146.161476 |    606.622464 | A. H. Baldwin (vectorized by T. Michael Keesey)                                                                                                                       |
| 802 |    213.550287 |    266.889952 | Margot Michaud                                                                                                                                                        |
| 803 |    394.738244 |    637.921365 | Yan Wong from photo by Denes Emoke                                                                                                                                    |
| 804 |    872.127181 |    584.853506 | Dmitry Bogdanov                                                                                                                                                       |
| 805 |    806.318990 |    196.609252 | Steven Traver                                                                                                                                                         |
| 806 |     49.575691 |    595.440760 | Zimices                                                                                                                                                               |
| 807 |    734.828268 |    173.273863 | Margot Michaud                                                                                                                                                        |
| 808 |    420.450354 |    596.999814 | Matt Crook                                                                                                                                                            |
| 809 |    235.526346 |    448.815852 | Ferran Sayol                                                                                                                                                          |
| 810 |    588.156730 |      8.698171 | Christoph Schomburg                                                                                                                                                   |
| 811 |    499.477182 |    656.498143 | Christoph Schomburg                                                                                                                                                   |
| 812 |    801.563702 |    451.428135 | Jennifer Trimble                                                                                                                                                      |
| 813 |     40.827308 |    505.349465 | Ingo Braasch                                                                                                                                                          |
| 814 |    386.981464 |    421.242934 | Birgit Lang                                                                                                                                                           |
| 815 |    820.368051 |    552.271021 | Steven Traver                                                                                                                                                         |
| 816 |    838.609045 |    349.322072 | Scott Hartman (vectorized by T. Michael Keesey)                                                                                                                       |
| 817 |    602.654502 |    209.111909 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                                 |
| 818 |    699.990422 |    584.291864 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                                     |
| 819 |    185.393402 |    668.023414 | Jessica Rick                                                                                                                                                          |
| 820 |    635.125616 |    123.945994 | Gareth Monger                                                                                                                                                         |
| 821 |    512.389330 |    573.233378 | Jagged Fang Designs                                                                                                                                                   |
| 822 |    146.570826 |    196.536536 | Zimices                                                                                                                                                               |
| 823 |    138.413582 |    577.987719 | Crystal Maier                                                                                                                                                         |
| 824 |    216.161453 |    633.314009 | Zimices                                                                                                                                                               |
| 825 |    980.784493 |    569.095218 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 826 |    493.142550 |    474.384887 | Matt Celeskey                                                                                                                                                         |
| 827 |     77.561694 |    603.944793 | John Gould (vectorized by T. Michael Keesey)                                                                                                                          |
| 828 |    821.980810 |    739.384046 | Matt Martyniuk                                                                                                                                                        |
| 829 |     53.669432 |    464.145828 | Gareth Monger                                                                                                                                                         |
| 830 |    718.653001 |    153.736961 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 831 |    423.077374 |    345.570667 | Jagged Fang Designs                                                                                                                                                   |
| 832 |    750.815770 |    194.087931 | Renata F. Martins                                                                                                                                                     |
| 833 |    946.598726 |    778.545991 | Danielle Alba                                                                                                                                                         |
| 834 |   1013.610649 |    448.985341 | Scott Hartman                                                                                                                                                         |
| 835 |    407.202167 |    254.250980 | Zimices                                                                                                                                                               |
| 836 |    923.650633 |    550.510367 | Caleb M. Brown                                                                                                                                                        |
| 837 |    194.543679 |    473.278487 | Martin R. Smith                                                                                                                                                       |
| 838 |    200.306392 |    457.838850 | Harold N Eyster                                                                                                                                                       |
| 839 |    649.350384 |    299.961850 | Almandine (vectorized by T. Michael Keesey)                                                                                                                           |
| 840 |    542.280701 |    482.387956 | Jonathan Wells                                                                                                                                                        |
| 841 |    996.616933 |    335.253228 | Tyler Greenfield                                                                                                                                                      |
| 842 |    257.444679 |    517.191918 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 843 |     28.776286 |    120.954684 | Zimices                                                                                                                                                               |
| 844 |    504.662041 |    248.089030 | T. Michael Keesey                                                                                                                                                     |
| 845 |     90.293835 |    672.019635 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 846 |    656.554281 |    526.829820 | Zimices                                                                                                                                                               |
| 847 |    562.382814 |    637.685321 | T. Michael Keesey (vectorization) and Nadiatalent (photography)                                                                                                       |
| 848 |    884.486396 |     14.595370 | Margot Michaud                                                                                                                                                        |
| 849 |    113.853410 |    719.103154 | Carlos Cano-Barbacil                                                                                                                                                  |
| 850 |    759.700722 |    218.125494 | T. Tischler                                                                                                                                                           |
| 851 |    792.723102 |    387.399758 | Zimices                                                                                                                                                               |
| 852 |    678.358060 |    789.064734 | Michelle Site                                                                                                                                                         |
| 853 |    650.710235 |    249.623977 | Steven Traver                                                                                                                                                         |
| 854 |    662.331201 |    775.667608 | Margot Michaud                                                                                                                                                        |
| 855 |    131.470378 |    670.893712 | Jagged Fang Designs                                                                                                                                                   |
| 856 |    555.105311 |    672.278577 | NA                                                                                                                                                                    |
| 857 |    680.889074 |    574.418689 | Matt Crook                                                                                                                                                            |
| 858 |    710.021030 |    483.009132 | Dmitry Bogdanov                                                                                                                                                       |
| 859 |    681.224558 |    161.773754 | Zimices                                                                                                                                                               |
| 860 |    143.073466 |    622.629354 | Margot Michaud                                                                                                                                                        |
| 861 |    393.352274 |    388.363015 | Dean Schnabel                                                                                                                                                         |
| 862 |    641.524841 |     56.956562 | Christoph Schomburg                                                                                                                                                   |
| 863 |    799.261818 |    280.557630 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 864 |    398.931239 |    263.075689 | Iain Reid                                                                                                                                                             |
| 865 |    648.263098 |     27.977788 | Gareth Monger                                                                                                                                                         |
| 866 |     15.488532 |    462.519202 | Sarah Werning                                                                                                                                                         |
| 867 |    648.591127 |    756.644461 | Matt Crook                                                                                                                                                            |
| 868 |    844.153510 |    168.074639 | Matt Crook                                                                                                                                                            |
| 869 |    802.649864 |    551.335264 | Kai R. Caspar                                                                                                                                                         |
| 870 |    240.687275 |    187.710569 | Zimices                                                                                                                                                               |
| 871 |    553.636468 |    513.303932 | Martin Kevil                                                                                                                                                          |
| 872 |    665.882299 |    210.467130 | Scott Hartman                                                                                                                                                         |
| 873 |    342.973497 |    475.077304 | Scott D. Sampson, Mark A. Loewen, Andrew A. Farke, Eric M. Roberts, Catherine A. Forster, Joshua A. Smith, Alan L. Titus                                              |
| 874 |    295.878146 |    630.434815 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 875 |    391.920794 |    523.477331 | Margot Michaud                                                                                                                                                        |
| 876 |    226.527421 |    555.342194 | Jose Carlos Arenas-Monroy                                                                                                                                             |
| 877 |   1005.699482 |    131.196292 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                                     |
| 878 |    573.240160 |    529.871117 | Andrew A. Farke                                                                                                                                                       |
| 879 |    686.598310 |    546.070867 | nicubunu                                                                                                                                                              |
| 880 |   1004.965665 |    575.614998 | Matt Crook                                                                                                                                                            |
| 881 |    391.917460 |    231.557795 | Tess Linden                                                                                                                                                           |
| 882 |    539.143579 |    119.075776 | Nobu Tamura, vectorized by Zimices                                                                                                                                    |
| 883 |    110.545394 |    780.683866 | Ellen Edmonson and Hugh Chrisp (vectorized by T. Michael Keesey)                                                                                                      |
| 884 |    309.186304 |     27.520595 | Dean Schnabel                                                                                                                                                         |
| 885 |     28.918893 |    685.628188 | Zimices                                                                                                                                                               |
| 886 |    977.769803 |    187.657413 | Margot Michaud                                                                                                                                                        |
| 887 |    354.805327 |    729.318294 | Gabriela Palomo-Munoz                                                                                                                                                 |
| 888 |    406.735800 |    204.339579 | Falconaumanni and T. Michael Keesey                                                                                                                                   |
| 889 |    464.038846 |    665.772776 | Stacy Spensley (Modified)                                                                                                                                             |
| 890 |     19.832867 |    257.704313 | Margot Michaud                                                                                                                                                        |
| 891 |    878.676491 |    523.602708 | Margot Michaud                                                                                                                                                        |
| 892 |     15.806061 |    517.706144 | Sergio A. Muñoz-Gómez                                                                                                                                                 |
| 893 |    167.457230 |    774.884645 | Zimices                                                                                                                                                               |
| 894 |    833.363313 |    402.161443 | Yan Wong                                                                                                                                                              |
| 895 |    457.597780 |    467.269735 | Ferran Sayol                                                                                                                                                          |
| 896 |    376.851845 |    316.811877 | Jim Bendon (photography) and T. Michael Keesey (vectorization)                                                                                                        |
| 897 |    752.086922 |    434.902386 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                         |
| 898 |     76.801389 |    489.314096 | Maija Karala                                                                                                                                                          |
| 899 |    332.558583 |    524.693225 | Lafage                                                                                                                                                                |
| 900 |    818.521111 |     51.113850 | Ludwik Gąsiorowski                                                                                                                                                    |
| 901 |    428.372129 |    426.379518 | Lankester Edwin Ray (vectorized by T. Michael Keesey)                                                                                                                 |
| 902 |    858.790354 |    257.647517 | Scott Hartman                                                                                                                                                         |
| 903 |    617.501698 |    194.295298 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                              |
| 904 |    906.880456 |    442.437319 | Mattia Menchetti / Yan Wong                                                                                                                                           |
| 905 |    818.466363 |    536.658888 | NA                                                                                                                                                                    |
| 906 |    714.185547 |    629.558551 | NA                                                                                                                                                                    |
| 907 |    913.924873 |    561.517524 | Felix Vaux                                                                                                                                                            |
| 908 |    499.076914 |    649.837439 | Michael P. Taylor                                                                                                                                                     |
| 909 |    955.094014 |    351.920475 | NA                                                                                                                                                                    |
| 910 |    484.606318 |    652.613059 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                              |
| 911 |    690.876423 |    303.113223 | Birgit Lang                                                                                                                                                           |
| 912 |     29.583841 |    414.885937 | Matt Crook                                                                                                                                                            |
| 913 |    157.403109 |    163.282153 | Gareth Monger                                                                                                                                                         |
| 914 |    206.050770 |    543.197339 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                                       |

    #> Your tweet has been posted!
