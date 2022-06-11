
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

Ferran Sayol, Lukas Panzarin, Iain Reid, Matt Crook, Gabriela
Palomo-Munoz, Steven Traver, Bennet McComish, photo by Avenue, Gareth
Monger, L. Shyamal, Tracy A. Heath, Michelle Site, Melissa Ingala,
Markus A. Grohme, Timothy Knepp (vectorized by T. Michael Keesey), Sarah
Werning, Prathyush Thomas, Alexander Schmidt-Lebuhn, Tasman Dixon,
Margot Michaud, Pedro de Siracusa, Mali’o Kodis, photograph by Jim
Vargo, Zimices, Mathilde Cordellier, Christine Axon, Duane Raver
(vectorized by T. Michael Keesey), Ingo Braasch, Mette Aumala, Alex
Slavenko, Birgit Lang, Ghedoghedo (vectorized by T. Michael Keesey), Yan
Wong, Erika Schumacher, Andy Wilson, Rebecca Groom, Scott Hartman,
Jagged Fang Designs, Steven Coombs, Nobu Tamura, vectorized by Zimices,
Nobu Tamura (vectorized by T. Michael Keesey), Ralf Janssen,
Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael
Keesey), Kai R. Caspar, Emily Willoughby, Michael B. H. (vectorized by
T. Michael Keesey), Michael Ströck (vectorized by T. Michael Keesey),
Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey), Joanna
Wolfe, T. Michael Keesey (after Mivart), Campbell Fleming, Caleb M.
Brown, Crystal Maier, nicubunu, Chris huh, Marie-Aimée Allard, Lani
Mohan, Felix Vaux, Melissa Broussard, Mathieu Basille, Daniel
Stadtmauer, Matt Martyniuk, T. Michael Keesey, Dmitry Bogdanov
(vectorized by T. Michael Keesey), M Kolmann, Jimmy Bernot, Kelly, Jaime
Headden, Diana Pomeroy, Kamil S. Jaron, Alexandre Vong, Beth Reinke,
Hugo Gruson, T. Michael Keesey (after James & al.), C. Camilo
Julián-Caballero, Apokryltaros (vectorized by T. Michael Keesey),
Mali’o Kodis, photograph by Melissa Frey, I. Sáček, Sr. (vectorized by
T. Michael Keesey), Oscar Sanisidro, Jon Hill (Photo by Benjamint444:
<http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>), Cristina
Guijarro, Katie S. Collins, Benjamint444, Harold N Eyster, Mathew Wedel,
U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley
(silhouette), Noah Schlottman, photo by Casey Dunn, A. R. McCulloch
(vectorized by T. Michael Keesey), Jiekun He, CNZdenek, Tauana J. Cunha,
Haplochromis (vectorized by T. Michael Keesey), Amanda Katzer, Roberto
Diaz Sibaja, based on Domser, Shyamal, Dmitry Bogdanov, Jaime A. Headden
(vectorized by T. Michael Keesey), Hans Hillewaert (photo) and T.
Michael Keesey (vectorization), S.Martini, Lukasiniho, Michael Day,
Christian A. Masnaghetti, B. Duygu Özpolat, Yan Wong from SEM by Arnau
Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo), Jan A. Venter, Herbert H.
T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael
Keesey), Lily Hughes, Andrew A. Farke, Rebecca Groom (Based on Photo by
Andreas Trepte), Christoph Schomburg, xgirouxb, Sharon Wegner-Larsen,
Roderic Page and Lois Page, Jack Mayer Wood, Vijay Cavale (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Isaure
Scavezzoni, Lafage, Robert Bruce Horsfall (vectorized by William
Gearty), Caleb Brown, Danny Cicchetti (vectorized by T. Michael Keesey),
Fernando Carezzano, Michael Scroggie, Noah Schlottman, photo by Gustav
Paulay for Moorea Biocode, Dann Pigdon, Roberto Díaz Sibaja, Francisco
Manuel Blanco (vectorized by T. Michael Keesey), Stemonitis
(photography) and T. Michael Keesey (vectorization), Mathieu Pélissié,
Mike Hanson, Evan-Amos (vectorized by T. Michael Keesey), Jaime Chirinos
(vectorized by T. Michael Keesey), Maxime Dahirel, Karl Ragnar Gjertsen
(vectorized by T. Michael Keesey), Chuanixn Yu, Margret Flinsch,
vectorized by Zimices, Becky Barnes, Ignacio Contreras, DW Bapst
(modified from Bates et al., 2005), Karla Martinez, Tyler Greenfield and
Dean Schnabel, NOAA Great Lakes Environmental Research Laboratory
(illustration) and Timothy J. Bartley (silhouette), Chloé Schmidt,
Joseph Smit (modified by T. Michael Keesey), Hans Hillewaert (vectorized
by T. Michael Keesey), Terpsichores, Danielle Alba, (unknown), Peter
Coxhead, Adam Stuart Smith (vectorized by T. Michael Keesey), Ellen
Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley
(silhouette), Ludwik Gąsiorowski, Michael Scroggie, from original
photograph by Gary M. Stolz, USFWS (original photograph in public
domain)., Matthias Buschmann (vectorized by T. Michael Keesey), Dean
Schnabel, Abraão B. Leite, Matus Valach, David Orr, Ramona J Heim, Tyler
McCraney, Noah Schlottman, Renata F. Martins, Paul Baker (photo), John
E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G.
Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey, Nobu
Tamura and T. Michael Keesey, T. Michael Keesey (after Mauricio Antón),
Neil Kelley, Rachel Shoop, Obsidian Soul (vectorized by T. Michael
Keesey), Chris Jennings (vectorized by A. Verrière), Matt Celeskey,
Lauren Sumner-Rooney, Carlos Cano-Barbacil, Elizabeth Parker, Pearson
Scott Foresman (vectorized by T. Michael Keesey), E. R. Waite & H. M.
Hale (vectorized by T. Michael Keesey), Cesar Julian, Roger Witter,
vectorized by Zimices, Anthony Caravaggi, Collin Gross, Marcos
Pérez-Losada, Jens T. Høeg & Keith A. Crandall, Gopal Murali, Noah
Schlottman, photo by Carlos Sánchez-Ortiz, Ben Liebeskind, Allison
Pease, I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey),
Zimices, based in Mauricio Antón skeletal, T. Michael Keesey, from a
photograph by Thea Boodhoo, Trond R. Oskars, Martin Kevil, Sam
Fraser-Smith (vectorized by T. Michael Keesey), Antonov (vectorized by
T. Michael Keesey), Archaeodontosaurus (vectorized by T. Michael
Keesey), Warren H (photography), T. Michael Keesey (vectorization),
Mason McNair, Matthew E. Clapham, Charles R. Knight, vectorized by
Zimices, Julio Garza, Kailah Thorn & Mark Hutchinson, Zimices / Julián
Bayona, T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler,
Ted M. Townsend & Miguel Vences), Lisa Byrne, Matt Martyniuk (modified
by T. Michael Keesey), Ewald Rübsamen, White Wolf, FunkMonk (Michael B.
H.), Smokeybjb, Maija Karala, Peileppe, Javier Luque & Sarah Gerken, Sam
Droege (photography) and T. Michael Keesey (vectorization), Conty, Óscar
San−Isidro (vectorized by T. Michael Keesey), Jessica Rick, Francisco
Gascó (modified by Michael P. Taylor), Thibaut Brunet, Gregor Bucher,
Max Farnworth, Sidney Frederic Harmer, Arthur Everett Shipley
(vectorized by Maxime Dahirel), Armin Reindl, terngirl, Milton Tan,
Jaime Headden, modified by T. Michael Keesey, Smokeybjb, vectorized by
Zimices, NASA, Zachary Quigley, T. Michael Keesey (photo by Bc999
\[Black crow\]), Brad McFeeters (vectorized by T. Michael Keesey), Dori
<dori@merr.info> (source photo) and Nevit Dilmen, Mo Hassan, Francesca
Belem Lopes Palmeira, Didier Descouens (vectorized by T. Michael
Keesey), Kanako Bessho-Uehara, Andrés Sánchez, \[unknown\], Matt
Wilkins, Stanton F. Fink (vectorized by T. Michael Keesey), Oren Peles /
vectorized by Yan Wong, Scott Reid, Matt Martyniuk (vectorized by T.
Michael Keesey), Renato Santos, T. Michael Keesey (after Kukalová),
Mariana Ruiz Villarreal, Kent Elson Sorgon, Yan Wong from drawing in The
Century Dictionary (1911), Chris A. Hamilton, Geoff Shaw, Jose Carlos
Arenas-Monroy, Tyler Greenfield and Scott Hartman, Mathew Stewart, T.
Michael Keesey (from a mount by Allis Markham), Robbie N. Cada (modified
by T. Michael Keesey), Robert Gay, Tim H. Heupink, Leon Huynen, and
David M. Lambert (vectorized by T. Michael Keesey), Michele M Tobias,
Xavier Giroux-Bougard, U.S. National Park Service (vectorized by William
Gearty), Henry Fairfield Osborn, vectorized by Zimices, James R. Spotila
and Ray Chatterji, Matt Wilkins (photo by Patrick Kavanagh), M. Antonio
Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized
by T. Michael Keesey), Air Kebir NRG, Jessica Anne Miller, Tyler
Greenfield, Servien (vectorized by T. Michael Keesey), Aline M.
Ghilardi, Charles Doolittle Walcott (vectorized by T. Michael Keesey),
Noah Schlottman, photo by David J Patterson, Nina Skinner, Konsta
Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist, Kanchi
Nanjo, Chris Hay, Nobu Tamura, FJDegrange, Raven Amos, Conty (vectorized
by T. Michael Keesey), Ieuan Jones, T. Michael Keesey (vectorization);
Yves Bousquet (photography), Rene Martin, Frederick William Frohawk
(vectorized by T. Michael Keesey)

## Detailed credit:

|     | Image X Coord | Image Y Coord | Credit                                                                                                                                                       |
| --: | ------------: | ------------: | :----------------------------------------------------------------------------------------------------------------------------------------------------------- |
|   1 |    427.304414 |    514.928603 | Ferran Sayol                                                                                                                                                 |
|   2 |    245.456790 |    704.983579 | Lukas Panzarin                                                                                                                                               |
|   3 |    898.143299 |     51.648341 | Iain Reid                                                                                                                                                    |
|   4 |    525.359705 |    622.175518 | Matt Crook                                                                                                                                                   |
|   5 |    805.882336 |    307.006966 | NA                                                                                                                                                           |
|   6 |    675.033656 |    427.545453 | Gabriela Palomo-Munoz                                                                                                                                        |
|   7 |    237.162899 |    254.477866 | Steven Traver                                                                                                                                                |
|   8 |    348.751071 |    192.986913 | Bennet McComish, photo by Avenue                                                                                                                             |
|   9 |    461.949438 |     59.287383 | Gareth Monger                                                                                                                                                |
|  10 |    862.294884 |    120.816358 | L. Shyamal                                                                                                                                                   |
|  11 |    719.552607 |    129.350127 | Tracy A. Heath                                                                                                                                               |
|  12 |    582.918903 |    727.564518 | Michelle Site                                                                                                                                                |
|  13 |    759.630492 |    598.288154 | Matt Crook                                                                                                                                                   |
|  14 |    487.481812 |    416.719680 | Melissa Ingala                                                                                                                                               |
|  15 |    873.864114 |    226.999422 | Markus A. Grohme                                                                                                                                             |
|  16 |    558.943854 |     92.469753 | Timothy Knepp (vectorized by T. Michael Keesey)                                                                                                              |
|  17 |    141.714544 |    386.373997 | Sarah Werning                                                                                                                                                |
|  18 |    286.159650 |    512.344239 | Prathyush Thomas                                                                                                                                             |
|  19 |    107.477100 |    566.919398 | Alexander Schmidt-Lebuhn                                                                                                                                     |
|  20 |    939.445843 |    393.146239 | Markus A. Grohme                                                                                                                                             |
|  21 |    161.892680 |     76.561384 | Tasman Dixon                                                                                                                                                 |
|  22 |    210.557865 |    618.201683 | Margot Michaud                                                                                                                                               |
|  23 |    628.878358 |    156.836388 | Pedro de Siracusa                                                                                                                                            |
|  24 |    932.655294 |    479.242489 | Mali’o Kodis, photograph by Jim Vargo                                                                                                                        |
|  25 |    730.753718 |    529.948961 | Markus A. Grohme                                                                                                                                             |
|  26 |    925.770652 |    721.207183 | Matt Crook                                                                                                                                                   |
|  27 |    407.951370 |    388.231924 | Michelle Site                                                                                                                                                |
|  28 |    183.248052 |    252.426712 | Gabriela Palomo-Munoz                                                                                                                                        |
|  29 |    793.176305 |    769.785862 | Zimices                                                                                                                                                      |
|  30 |    416.342355 |    719.929061 | Sarah Werning                                                                                                                                                |
|  31 |    516.827637 |    254.334630 | Mathilde Cordellier                                                                                                                                          |
|  32 |    727.481323 |    241.197916 | Christine Axon                                                                                                                                               |
|  33 |    658.478397 |    624.634296 | NA                                                                                                                                                           |
|  34 |     66.426303 |    685.845658 | Duane Raver (vectorized by T. Michael Keesey)                                                                                                                |
|  35 |    314.234293 |    421.895520 | Ingo Braasch                                                                                                                                                 |
|  36 |    714.209622 |     55.886825 | Mette Aumala                                                                                                                                                 |
|  37 |    623.918850 |    286.304422 | Sarah Werning                                                                                                                                                |
|  38 |    755.560450 |    466.509149 | Margot Michaud                                                                                                                                               |
|  39 |    863.340554 |    609.930713 | NA                                                                                                                                                           |
|  40 |    360.552275 |    593.606519 | Alex Slavenko                                                                                                                                                |
|  41 |    995.655407 |    234.930606 | Birgit Lang                                                                                                                                                  |
|  42 |    781.688148 |    668.962442 | Gareth Monger                                                                                                                                                |
|  43 |    540.824771 |    505.249901 | Gareth Monger                                                                                                                                                |
|  44 |    582.764605 |    380.553666 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
|  45 |    786.349746 |    388.634104 | Yan Wong                                                                                                                                                     |
|  46 |     75.087497 |    132.643563 | Erika Schumacher                                                                                                                                             |
|  47 |     33.288025 |    443.377611 | Andy Wilson                                                                                                                                                  |
|  48 |    382.019489 |    263.524436 | Rebecca Groom                                                                                                                                                |
|  49 |     67.236301 |     23.430633 | Tasman Dixon                                                                                                                                                 |
|  50 |    433.887274 |    168.191554 | Gareth Monger                                                                                                                                                |
|  51 |    123.023069 |    743.627430 | Scott Hartman                                                                                                                                                |
|  52 |    227.376071 |    765.698114 | Yan Wong                                                                                                                                                     |
|  53 |     71.253060 |    294.075327 | Gabriela Palomo-Munoz                                                                                                                                        |
|  54 |    415.585953 |    113.224715 | Margot Michaud                                                                                                                                               |
|  55 |     68.985704 |    231.033615 | Jagged Fang Designs                                                                                                                                          |
|  56 |    839.730786 |    242.848807 | Jagged Fang Designs                                                                                                                                          |
|  57 |    728.182826 |    206.477911 | Steven Coombs                                                                                                                                                |
|  58 |    104.810426 |    714.394433 | Nobu Tamura, vectorized by Zimices                                                                                                                           |
|  59 |    875.395529 |    190.555912 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
|  60 |    211.826625 |    470.341626 | Alex Slavenko                                                                                                                                                |
|  61 |    333.786198 |    645.294312 | Zimices                                                                                                                                                      |
|  62 |    950.190302 |    109.249480 | Ralf Janssen, Nikola-Michael Prpic & Wim G. M. Damen (vectorized by T. Michael Keesey)                                                                       |
|  63 |    947.987959 |    344.122734 | Birgit Lang                                                                                                                                                  |
|  64 |    299.850580 |     56.281179 | Kai R. Caspar                                                                                                                                                |
|  65 |     73.534455 |    170.017626 | Emily Willoughby                                                                                                                                             |
|  66 |    850.641683 |    741.813271 | NA                                                                                                                                                           |
|  67 |    590.155186 |     38.621662 | Michael B. H. (vectorized by T. Michael Keesey)                                                                                                              |
|  68 |    253.038789 |    356.559218 | Michael Ströck (vectorized by T. Michael Keesey)                                                                                                             |
|  69 |    203.604427 |     61.217306 | Margot Michaud                                                                                                                                               |
|  70 |    867.647173 |    549.480677 | Dmitry Bogdanov and FunkMonk (vectorized by T. Michael Keesey)                                                                                               |
|  71 |    945.196946 |    600.484974 | NA                                                                                                                                                           |
|  72 |    731.743152 |    700.262957 | Joanna Wolfe                                                                                                                                                 |
|  73 |    710.146396 |    350.209515 | T. Michael Keesey (after Mivart)                                                                                                                             |
|  74 |    611.921350 |    515.744286 | Rebecca Groom                                                                                                                                                |
|  75 |    350.196874 |    359.637042 | Campbell Fleming                                                                                                                                             |
|  76 |    940.324707 |    361.371827 | Matt Crook                                                                                                                                                   |
|  77 |    801.736844 |    679.239849 | Caleb M. Brown                                                                                                                                               |
|  78 |    781.052449 |     82.283845 | Crystal Maier                                                                                                                                                |
|  79 |    470.082053 |    593.110218 | Matt Crook                                                                                                                                                   |
|  80 |    125.583388 |    766.827876 | Steven Traver                                                                                                                                                |
|  81 |    819.503249 |    518.635028 | nicubunu                                                                                                                                                     |
|  82 |     32.994397 |    365.978701 | Chris huh                                                                                                                                                    |
|  83 |    449.465194 |    448.453062 | Marie-Aimée Allard                                                                                                                                           |
|  84 |    863.878943 |    687.128224 | Lani Mohan                                                                                                                                                   |
|  85 |     24.274296 |     53.678101 | Chris huh                                                                                                                                                    |
|  86 |     54.911798 |    792.718362 | Felix Vaux                                                                                                                                                   |
|  87 |   1007.445860 |    782.440585 | Melissa Broussard                                                                                                                                            |
|  88 |    454.879396 |    188.294004 | Gareth Monger                                                                                                                                                |
|  89 |    650.603625 |    771.608016 | Scott Hartman                                                                                                                                                |
|  90 |     85.521532 |    440.925401 | Mathieu Basille                                                                                                                                              |
|  91 |    985.205298 |    704.489852 | Margot Michaud                                                                                                                                               |
|  92 |    578.066704 |    155.678800 | Daniel Stadtmauer                                                                                                                                            |
|  93 |    863.988926 |    470.494786 | Matt Martyniuk                                                                                                                                               |
|  94 |    236.578253 |    428.863721 | Zimices                                                                                                                                                      |
|  95 |    444.749219 |    365.639679 | T. Michael Keesey                                                                                                                                            |
|  96 |    328.427579 |    531.589187 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
|  97 |    266.842662 |    127.247167 | Markus A. Grohme                                                                                                                                             |
|  98 |    708.920357 |    719.118354 | Gareth Monger                                                                                                                                                |
|  99 |    947.092295 |    795.565966 | M Kolmann                                                                                                                                                    |
| 100 |    513.840822 |    773.465013 | Jimmy Bernot                                                                                                                                                 |
| 101 |    303.827053 |    233.842676 | Kelly                                                                                                                                                        |
| 102 |   1014.828166 |    714.898719 | Kai R. Caspar                                                                                                                                                |
| 103 |     90.717889 |    622.441305 | Jaime Headden                                                                                                                                                |
| 104 |    479.957338 |    786.357109 | Diana Pomeroy                                                                                                                                                |
| 105 |    810.810581 |    148.378368 | Kamil S. Jaron                                                                                                                                               |
| 106 |    263.069403 |    644.391821 | Alexandre Vong                                                                                                                                               |
| 107 |    211.070001 |    441.471277 | Beth Reinke                                                                                                                                                  |
| 108 |    601.776101 |    633.934207 | Matt Crook                                                                                                                                                   |
| 109 |     67.931379 |    773.514734 | NA                                                                                                                                                           |
| 110 |    541.633395 |    488.458890 | Margot Michaud                                                                                                                                               |
| 111 |    713.705203 |    572.468142 | Chris huh                                                                                                                                                    |
| 112 |    448.038317 |    635.528495 | Zimices                                                                                                                                                      |
| 113 |    798.592039 |     31.706724 | Hugo Gruson                                                                                                                                                  |
| 114 |    347.053075 |    512.760724 | Joanna Wolfe                                                                                                                                                 |
| 115 |    935.418622 |    279.095466 | NA                                                                                                                                                           |
| 116 |    498.916988 |     10.580926 | Scott Hartman                                                                                                                                                |
| 117 |    627.128786 |     17.962536 | Beth Reinke                                                                                                                                                  |
| 118 |     33.566267 |    387.941102 | Andy Wilson                                                                                                                                                  |
| 119 |    796.671390 |    608.403557 | T. Michael Keesey (after James & al.)                                                                                                                        |
| 120 |    218.853148 |    126.204267 | C. Camilo Julián-Caballero                                                                                                                                   |
| 121 |    265.365336 |    401.838231 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                               |
| 122 |    488.969810 |    372.622609 | Margot Michaud                                                                                                                                               |
| 123 |    510.010623 |    153.268679 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 124 |    323.478198 |    372.616850 | Margot Michaud                                                                                                                                               |
| 125 |     51.469421 |    655.891778 | Margot Michaud                                                                                                                                               |
| 126 |    596.786865 |    586.016227 | Mali’o Kodis, photograph by Melissa Frey                                                                                                                     |
| 127 |    543.940392 |    768.078682 | I. Sáček, Sr. (vectorized by T. Michael Keesey)                                                                                                              |
| 128 |    958.135301 |    274.461793 | Matt Crook                                                                                                                                                   |
| 129 |     73.014357 |     74.047558 | Andy Wilson                                                                                                                                                  |
| 130 |    473.134893 |    703.066907 | Zimices                                                                                                                                                      |
| 131 |    248.807401 |    279.399048 | Alexandre Vong                                                                                                                                               |
| 132 |    788.278440 |    511.381292 | Margot Michaud                                                                                                                                               |
| 133 |    436.304022 |    570.500599 | Oscar Sanisidro                                                                                                                                              |
| 134 |    366.668057 |    792.251605 | Chris huh                                                                                                                                                    |
| 135 |    484.923264 |    533.204471 | Scott Hartman                                                                                                                                                |
| 136 |    691.649373 |    151.850665 | Jagged Fang Designs                                                                                                                                          |
| 137 |    869.995231 |    786.094785 | L. Shyamal                                                                                                                                                   |
| 138 |    938.789125 |    422.124747 | NA                                                                                                                                                           |
| 139 |     12.724998 |    380.688208 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 140 |    403.768109 |    149.018723 | Margot Michaud                                                                                                                                               |
| 141 |    791.270563 |    120.924540 | NA                                                                                                                                                           |
| 142 |    800.348600 |    359.909638 | Jon Hill (Photo by Benjamint444: <http://en.wikipedia.org/wiki/File:Blue-footed-booby.jpg>)                                                                  |
| 143 |   1020.595086 |    500.605490 | Gareth Monger                                                                                                                                                |
| 144 |    711.777974 |     13.635635 | Andy Wilson                                                                                                                                                  |
| 145 |    693.719575 |     29.871552 | Chris huh                                                                                                                                                    |
| 146 |    248.703274 |    316.501027 | Cristina Guijarro                                                                                                                                            |
| 147 |    216.129468 |    402.101504 | Katie S. Collins                                                                                                                                             |
| 148 |     78.923325 |    606.810024 | Scott Hartman                                                                                                                                                |
| 149 |    546.730401 |    682.023041 | Scott Hartman                                                                                                                                                |
| 150 |    884.338965 |     99.009534 | T. Michael Keesey                                                                                                                                            |
| 151 |    911.941248 |     14.088132 | Margot Michaud                                                                                                                                               |
| 152 |    371.229647 |    483.071953 | Chris huh                                                                                                                                                    |
| 153 |    833.847838 |    425.422316 | Matt Crook                                                                                                                                                   |
| 154 |    970.715769 |    262.365858 | Benjamint444                                                                                                                                                 |
| 155 |    683.715549 |    283.716716 | Harold N Eyster                                                                                                                                              |
| 156 |     13.716454 |    746.221613 | Mathew Wedel                                                                                                                                                 |
| 157 |    974.203757 |    308.027924 | Birgit Lang                                                                                                                                                  |
| 158 |    978.551466 |    135.906529 | Gabriela Palomo-Munoz                                                                                                                                        |
| 159 |   1006.552235 |    106.305710 | U.S. Fish and Wildlife Service (illustration) and Timothy J. Bartley (silhouette)                                                                            |
| 160 |    175.351163 |    352.765605 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 161 |    900.106333 |    417.834790 | Gabriela Palomo-Munoz                                                                                                                                        |
| 162 |     28.119777 |    663.983074 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                            |
| 163 |    458.234326 |    270.181633 | Jiekun He                                                                                                                                                    |
| 164 |    750.638854 |     76.343136 | Margot Michaud                                                                                                                                               |
| 165 |    779.744490 |    236.910782 | CNZdenek                                                                                                                                                     |
| 166 |    813.334874 |    501.792909 | Tauana J. Cunha                                                                                                                                              |
| 167 |    184.494137 |    314.392759 | Mathilde Cordellier                                                                                                                                          |
| 168 |    608.478849 |    475.902975 | Matt Crook                                                                                                                                                   |
| 169 |    459.696663 |    343.480460 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                               |
| 170 |    202.060837 |    653.631102 | Amanda Katzer                                                                                                                                                |
| 171 |    307.270409 |    184.737939 | Roberto Diaz Sibaja, based on Domser                                                                                                                         |
| 172 |    111.221731 |    264.083444 | Markus A. Grohme                                                                                                                                             |
| 173 |    720.203513 |    422.866499 | Steven Traver                                                                                                                                                |
| 174 |    657.731889 |    507.023031 | Shyamal                                                                                                                                                      |
| 175 |    349.280661 |    561.400452 | Dmitry Bogdanov                                                                                                                                              |
| 176 |     97.565368 |    338.804300 | Andy Wilson                                                                                                                                                  |
| 177 |    973.210738 |    779.554313 | NA                                                                                                                                                           |
| 178 |    168.172806 |    127.969800 | Jaime A. Headden (vectorized by T. Michael Keesey)                                                                                                           |
| 179 |     69.411132 |    344.094185 | Hans Hillewaert (photo) and T. Michael Keesey (vectorization)                                                                                                |
| 180 |    751.534449 |    566.821410 | Ferran Sayol                                                                                                                                                 |
| 181 |    381.117150 |    773.192324 | S.Martini                                                                                                                                                    |
| 182 |    230.257419 |    677.065698 | Lukasiniho                                                                                                                                                   |
| 183 |    522.063411 |    121.847908 | Michael Day                                                                                                                                                  |
| 184 |    264.899497 |    608.577128 | Christian A. Masnaghetti                                                                                                                                     |
| 185 |    288.584853 |    682.516794 | Amanda Katzer                                                                                                                                                |
| 186 |    391.393446 |    406.910810 | Matt Crook                                                                                                                                                   |
| 187 |    998.523248 |    416.606884 | B. Duygu Özpolat                                                                                                                                             |
| 188 |    141.160560 |    314.540069 | NA                                                                                                                                                           |
| 189 |   1007.019180 |    491.554659 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 190 |     12.400369 |     44.316112 | Yan Wong from SEM by Arnau Sebé-Pedrós (PD agreed by Iñaki Ruiz-Trillo)                                                                                      |
| 191 |    550.824655 |    183.905784 | Ferran Sayol                                                                                                                                                 |
| 192 |      3.969814 |    116.988134 | Felix Vaux                                                                                                                                                   |
| 193 |    321.103269 |    551.422089 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 194 |    182.501148 |    359.995554 | Lily Hughes                                                                                                                                                  |
| 195 |    828.055375 |    616.638393 | L. Shyamal                                                                                                                                                   |
| 196 |     83.015564 |    323.687398 | NA                                                                                                                                                           |
| 197 |    965.980102 |    566.020167 | Matt Martyniuk                                                                                                                                               |
| 198 |    613.013321 |    610.110705 | T. Michael Keesey                                                                                                                                            |
| 199 |    322.138854 |    515.691027 | Michelle Site                                                                                                                                                |
| 200 |    920.081534 |    402.308853 | Ferran Sayol                                                                                                                                                 |
| 201 |    993.216403 |    369.171122 | Yan Wong                                                                                                                                                     |
| 202 |    580.037621 |     55.113596 | Chris huh                                                                                                                                                    |
| 203 |    626.789113 |    477.412983 | Birgit Lang                                                                                                                                                  |
| 204 |    121.468836 |    288.836216 | Andrew A. Farke                                                                                                                                              |
| 205 |    628.465892 |    337.187431 | Zimices                                                                                                                                                      |
| 206 |    648.442813 |    686.254786 | NA                                                                                                                                                           |
| 207 |    978.582576 |    595.173670 | NA                                                                                                                                                           |
| 208 |    662.926385 |    341.064803 | Steven Coombs                                                                                                                                                |
| 209 |    557.745332 |    439.128257 | Matt Crook                                                                                                                                                   |
| 210 |    659.193078 |     97.440741 | Rebecca Groom (Based on Photo by Andreas Trepte)                                                                                                             |
| 211 |    365.169531 |    619.248610 | Christoph Schomburg                                                                                                                                          |
| 212 |   1008.050185 |    581.883457 | xgirouxb                                                                                                                                                     |
| 213 |    963.590863 |    632.292107 | Margot Michaud                                                                                                                                               |
| 214 |    434.518963 |    466.906618 | Ferran Sayol                                                                                                                                                 |
| 215 |    214.844411 |    146.541868 | Jagged Fang Designs                                                                                                                                          |
| 216 |    760.165868 |    277.071147 | Gabriela Palomo-Munoz                                                                                                                                        |
| 217 |    317.853455 |    133.396291 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 218 |    208.903209 |    682.729099 | Sharon Wegner-Larsen                                                                                                                                         |
| 219 |     54.795437 |    429.690063 | Scott Hartman                                                                                                                                                |
| 220 |    999.011740 |    505.112441 | Markus A. Grohme                                                                                                                                             |
| 221 |    355.906128 |    127.600339 | Roderic Page and Lois Page                                                                                                                                   |
| 222 |    939.148273 |    271.758305 | Jack Mayer Wood                                                                                                                                              |
| 223 |    515.487653 |    734.348961 | Vijay Cavale (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey |
| 224 |    418.222083 |    553.116147 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 225 |    625.338850 |    664.361355 | Gabriela Palomo-Munoz                                                                                                                                        |
| 226 |     82.173545 |     90.339373 | Isaure Scavezzoni                                                                                                                                            |
| 227 |    205.021270 |    364.673912 | Sarah Werning                                                                                                                                                |
| 228 |     20.349155 |    315.168939 | Caleb M. Brown                                                                                                                                               |
| 229 |    271.315731 |    575.608333 | Steven Traver                                                                                                                                                |
| 230 |    465.829570 |     18.717365 | Lafage                                                                                                                                                       |
| 231 |    159.716960 |    716.553332 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                         |
| 232 |    985.732790 |    728.582630 | Caleb Brown                                                                                                                                                  |
| 233 |    863.322526 |    402.895908 | Christoph Schomburg                                                                                                                                          |
| 234 |     55.198246 |    618.883251 | NA                                                                                                                                                           |
| 235 |    710.556789 |    600.667613 | Danny Cicchetti (vectorized by T. Michael Keesey)                                                                                                            |
| 236 |    662.540363 |    172.968545 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 237 |    243.477179 |     92.754261 | T. Michael Keesey                                                                                                                                            |
| 238 |    674.679422 |    253.423550 | Steven Traver                                                                                                                                                |
| 239 |    980.213548 |    153.505698 | Fernando Carezzano                                                                                                                                           |
| 240 |    424.022540 |     11.812280 | Matt Crook                                                                                                                                                   |
| 241 |    835.516332 |    359.225997 | Ferran Sayol                                                                                                                                                 |
| 242 |    745.509553 |    633.853140 | Michael Scroggie                                                                                                                                             |
| 243 |    170.905434 |    665.399274 | Noah Schlottman, photo by Gustav Paulay for Moorea Biocode                                                                                                   |
| 244 |    324.219401 |    776.967327 | Markus A. Grohme                                                                                                                                             |
| 245 |    798.174589 |    601.256946 | Zimices                                                                                                                                                      |
| 246 |    587.062297 |    783.122763 | Dann Pigdon                                                                                                                                                  |
| 247 |    117.391352 |    656.058803 | Andrew A. Farke                                                                                                                                              |
| 248 |    527.214111 |    429.146497 | Christoph Schomburg                                                                                                                                          |
| 249 |    976.094912 |     60.793458 | Gabriela Palomo-Munoz                                                                                                                                        |
| 250 |    898.969883 |    295.715078 | NA                                                                                                                                                           |
| 251 |    628.804724 |    692.091235 | Matt Crook                                                                                                                                                   |
| 252 |    586.851089 |    289.998665 | Tauana J. Cunha                                                                                                                                              |
| 253 |    459.809037 |    243.594352 | Tauana J. Cunha                                                                                                                                              |
| 254 |    129.148126 |     43.234417 | Jan A. Venter, Herbert H. T. Prins, David A. Balfour & Rob Slotow (vectorized by T. Michael Keesey)                                                          |
| 255 |    448.265842 |    620.246484 | Matt Martyniuk                                                                                                                                               |
| 256 |    974.568121 |     20.592815 | Zimices                                                                                                                                                      |
| 257 |    587.588790 |    454.602667 | Matt Crook                                                                                                                                                   |
| 258 |    647.052419 |    360.478814 | Matt Crook                                                                                                                                                   |
| 259 |    248.150161 |    669.333314 | Steven Traver                                                                                                                                                |
| 260 |    657.075195 |     18.601110 | Markus A. Grohme                                                                                                                                             |
| 261 |    826.584060 |    700.237623 | Christoph Schomburg                                                                                                                                          |
| 262 |    968.718850 |    648.170010 | Christoph Schomburg                                                                                                                                          |
| 263 |    344.183751 |    140.723593 | Matt Crook                                                                                                                                                   |
| 264 |     82.333771 |    100.566163 | Roberto Díaz Sibaja                                                                                                                                          |
| 265 |    177.073618 |    571.759106 | T. Michael Keesey                                                                                                                                            |
| 266 |     71.316412 |    202.598920 | Francisco Manuel Blanco (vectorized by T. Michael Keesey)                                                                                                    |
| 267 |    546.801648 |    599.376391 | Stemonitis (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 268 |    596.419307 |    271.829633 | Andrew A. Farke                                                                                                                                              |
| 269 |    692.832443 |    745.068463 | Mathieu Pélissié                                                                                                                                             |
| 270 |    617.497047 |    776.491395 | Mike Hanson                                                                                                                                                  |
| 271 |    691.864009 |    502.813210 | Michelle Site                                                                                                                                                |
| 272 |    346.422649 |    676.553677 | Ferran Sayol                                                                                                                                                 |
| 273 |    643.803286 |    787.332014 | Ingo Braasch                                                                                                                                                 |
| 274 |    467.150697 |    671.282841 | Evan-Amos (vectorized by T. Michael Keesey)                                                                                                                  |
| 275 |     21.333211 |    100.555879 | Jaime Chirinos (vectorized by T. Michael Keesey)                                                                                                             |
| 276 |    601.511477 |      7.287408 | Maxime Dahirel                                                                                                                                               |
| 277 |    526.103142 |    636.135362 | Kai R. Caspar                                                                                                                                                |
| 278 |    823.914255 |     34.298968 | NA                                                                                                                                                           |
| 279 |    764.511529 |    424.761858 | Karl Ragnar Gjertsen (vectorized by T. Michael Keesey)                                                                                                       |
| 280 |    988.446474 |    559.237188 | Gareth Monger                                                                                                                                                |
| 281 |    388.295886 |    470.951805 | Birgit Lang                                                                                                                                                  |
| 282 |    187.832131 |     23.176778 | Chuanixn Yu                                                                                                                                                  |
| 283 |    999.929790 |    385.773469 | C. Camilo Julián-Caballero                                                                                                                                   |
| 284 |    435.868892 |    146.668014 | Margret Flinsch, vectorized by Zimices                                                                                                                       |
| 285 |     81.344877 |    263.631079 | Becky Barnes                                                                                                                                                 |
| 286 |    517.848328 |    749.570376 | NA                                                                                                                                                           |
| 287 |    215.947200 |    299.743105 | Ignacio Contreras                                                                                                                                            |
| 288 |    962.102047 |    354.570515 | Gareth Monger                                                                                                                                                |
| 289 |    835.041609 |    490.653397 | Alexandre Vong                                                                                                                                               |
| 290 |    964.859272 |    413.535782 | Steven Traver                                                                                                                                                |
| 291 |      8.434891 |    175.746028 | DW Bapst (modified from Bates et al., 2005)                                                                                                                  |
| 292 |    847.720651 |     12.587693 | Christoph Schomburg                                                                                                                                          |
| 293 |    422.908686 |    589.643384 | Andy Wilson                                                                                                                                                  |
| 294 |     65.564825 |    107.713243 | Karla Martinez                                                                                                                                               |
| 295 |    964.879315 |    136.911405 | Gareth Monger                                                                                                                                                |
| 296 |     20.297568 |     27.746526 | Gabriela Palomo-Munoz                                                                                                                                        |
| 297 |     47.941800 |    639.957370 | Gabriela Palomo-Munoz                                                                                                                                        |
| 298 |    345.730872 |    749.196488 | T. Michael Keesey                                                                                                                                            |
| 299 |    917.860532 |    325.465618 | Tyler Greenfield and Dean Schnabel                                                                                                                           |
| 300 |     35.402992 |    757.394805 | Gareth Monger                                                                                                                                                |
| 301 |    575.649069 |     67.730217 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                        |
| 302 |    891.457142 |    788.079455 | Margot Michaud                                                                                                                                               |
| 303 |    472.778978 |    151.068186 | NA                                                                                                                                                           |
| 304 |    471.355985 |     69.305336 | Chloé Schmidt                                                                                                                                                |
| 305 |    106.218492 |    248.162197 | Chris huh                                                                                                                                                    |
| 306 |    262.152402 |    667.327202 | Scott Hartman                                                                                                                                                |
| 307 |    489.841912 |    139.844875 | Joseph Smit (modified by T. Michael Keesey)                                                                                                                  |
| 308 |   1007.472947 |    747.023168 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |
| 309 |    857.377595 |     70.506225 | Steven Traver                                                                                                                                                |
| 310 |    588.900446 |    692.280732 | Steven Traver                                                                                                                                                |
| 311 |     21.145234 |    610.534112 | Terpsichores                                                                                                                                                 |
| 312 |    329.239788 |    138.243249 | Steven Traver                                                                                                                                                |
| 313 |    201.747313 |    632.578900 | Scott Hartman                                                                                                                                                |
| 314 |    413.051475 |    659.462681 | Danielle Alba                                                                                                                                                |
| 315 |    358.851152 |    407.901409 | Tasman Dixon                                                                                                                                                 |
| 316 |    650.709156 |     75.675332 | Kamil S. Jaron                                                                                                                                               |
| 317 |    696.216075 |    667.964487 | Andy Wilson                                                                                                                                                  |
| 318 |    956.605725 |    219.841846 | Steven Traver                                                                                                                                                |
| 319 |    784.173891 |    731.526444 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 320 |    101.010175 |    255.105773 | (unknown)                                                                                                                                                    |
| 321 |    562.843472 |    681.158412 | Peter Coxhead                                                                                                                                                |
| 322 |    334.196753 |    259.436434 | Scott Hartman                                                                                                                                                |
| 323 |    427.613412 |     26.268769 | Matt Crook                                                                                                                                                   |
| 324 |    738.447498 |    283.943442 | NA                                                                                                                                                           |
| 325 |    105.712780 |    211.672305 | Gabriela Palomo-Munoz                                                                                                                                        |
| 326 |    607.653196 |    787.725487 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                          |
| 327 |    752.814491 |      8.448145 | Ellen Edmonson and Hugh Chrisp (illustration) and Timothy J. Bartley (silhouette)                                                                            |
| 328 |    537.844230 |    787.956168 | Ludwik Gąsiorowski                                                                                                                                           |
| 329 |    445.652441 |    425.823894 | Gareth Monger                                                                                                                                                |
| 330 |    691.371054 |     35.422506 | Markus A. Grohme                                                                                                                                             |
| 331 |    929.529938 |    529.375962 | Zimices                                                                                                                                                      |
| 332 |    760.791347 |     29.352042 | NA                                                                                                                                                           |
| 333 |    882.024099 |    368.532309 | Michael Scroggie, from original photograph by Gary M. Stolz, USFWS (original photograph in public domain).                                                   |
| 334 |    796.389230 |    203.578682 | Rebecca Groom                                                                                                                                                |
| 335 |    366.703600 |     54.032893 | NA                                                                                                                                                           |
| 336 |    752.702614 |    110.312153 | Margot Michaud                                                                                                                                               |
| 337 |    809.123752 |    658.925445 | Matthias Buschmann (vectorized by T. Michael Keesey)                                                                                                         |
| 338 |    147.262097 |    458.959235 | Zimices                                                                                                                                                      |
| 339 |    727.286694 |    765.593535 | Dean Schnabel                                                                                                                                                |
| 340 |    784.484207 |    161.674116 | Jack Mayer Wood                                                                                                                                              |
| 341 |    487.539613 |    496.267619 | Abraão B. Leite                                                                                                                                              |
| 342 |    573.691681 |    695.456930 | Matus Valach                                                                                                                                                 |
| 343 |    779.486216 |    343.450787 | David Orr                                                                                                                                                    |
| 344 |    955.449472 |    372.526305 | Zimices                                                                                                                                                      |
| 345 |    610.195203 |    444.977436 | Ignacio Contreras                                                                                                                                            |
| 346 |    250.937818 |    299.149983 | Jagged Fang Designs                                                                                                                                          |
| 347 |    849.567304 |    452.032206 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 348 |    292.247802 |    118.971299 | Steven Coombs                                                                                                                                                |
| 349 |    144.592362 |    602.318596 | Michelle Site                                                                                                                                                |
| 350 |    375.080607 |    339.744287 | NA                                                                                                                                                           |
| 351 |    680.229426 |    544.832737 | Margot Michaud                                                                                                                                               |
| 352 |     76.495014 |    353.486156 | Chris huh                                                                                                                                                    |
| 353 |    146.283199 |    150.924435 | Michael Scroggie                                                                                                                                             |
| 354 |    262.877100 |    621.479659 | Ramona J Heim                                                                                                                                                |
| 355 |     20.750296 |    165.414149 | Scott Hartman                                                                                                                                                |
| 356 |    509.415647 |    116.103877 | Dmitry Bogdanov                                                                                                                                              |
| 357 |    672.586600 |    291.404051 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 358 |    117.373921 |     47.346302 | Scott Hartman                                                                                                                                                |
| 359 |    512.812507 |     26.973425 | Steven Traver                                                                                                                                                |
| 360 |    504.653418 |    134.792339 | Tyler McCraney                                                                                                                                               |
| 361 |    826.885796 |    597.016889 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 362 |    597.856241 |    618.839198 | Steven Traver                                                                                                                                                |
| 363 |    338.588377 |    391.392510 | Noah Schlottman                                                                                                                                              |
| 364 |    834.594716 |    712.497766 | Scott Hartman                                                                                                                                                |
| 365 |     78.391622 |    409.246330 | Renata F. Martins                                                                                                                                            |
| 366 |    589.846579 |    609.007439 | Paul Baker (photo), John E. McCormack, Michael G. Harvey, Brant C. Faircloth, Nicholas G. Crawford, Travis C. Glenn, Robb T. Brumfield & T. Michael Keesey   |
| 367 |    671.323407 |     59.703690 | Joanna Wolfe                                                                                                                                                 |
| 368 |     17.437347 |    774.394931 | Nobu Tamura and T. Michael Keesey                                                                                                                            |
| 369 |    919.425003 |    300.284088 | Zimices                                                                                                                                                      |
| 370 |    872.804406 |     14.050408 | Gareth Monger                                                                                                                                                |
| 371 |    383.402590 |    762.702020 | T. Michael Keesey (after Mauricio Antón)                                                                                                                     |
| 372 |    390.185915 |    366.233039 | Zimices                                                                                                                                                      |
| 373 |    349.568718 |      9.829481 | Neil Kelley                                                                                                                                                  |
| 374 |    403.048084 |    241.863714 | Rachel Shoop                                                                                                                                                 |
| 375 |    978.580391 |    526.927327 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
| 376 |    560.828994 |     12.994452 | Chloé Schmidt                                                                                                                                                |
| 377 |     84.519881 |    752.130117 | Ferran Sayol                                                                                                                                                 |
| 378 |    512.723735 |    376.388954 | Zimices                                                                                                                                                      |
| 379 |    805.998701 |    197.775774 | Chris Jennings (vectorized by A. Verrière)                                                                                                                   |
| 380 |    952.854448 |     77.158692 | Scott Hartman                                                                                                                                                |
| 381 |      8.314796 |    142.604492 | Andy Wilson                                                                                                                                                  |
| 382 |    907.975950 |    281.608411 | Andy Wilson                                                                                                                                                  |
| 383 |    171.873300 |    217.756363 | Matt Celeskey                                                                                                                                                |
| 384 |    609.017520 |    426.339881 | Katie S. Collins                                                                                                                                             |
| 385 |    795.109106 |    656.649416 | Markus A. Grohme                                                                                                                                             |
| 386 |    423.898471 |    788.319672 | Matt Crook                                                                                                                                                   |
| 387 |    661.033164 |    230.005772 | Zimices                                                                                                                                                      |
| 388 |     22.102552 |    622.717477 | Ferran Sayol                                                                                                                                                 |
| 389 |     19.914309 |    763.018189 | Christoph Schomburg                                                                                                                                          |
| 390 |    739.079900 |    600.920942 | Lauren Sumner-Rooney                                                                                                                                         |
| 391 |    499.001183 |    731.623937 | Margot Michaud                                                                                                                                               |
| 392 |    134.976875 |    179.630864 | Sarah Werning                                                                                                                                                |
| 393 |    290.515715 |    556.331211 | Matt Crook                                                                                                                                                   |
| 394 |     50.325793 |    210.908535 | Gareth Monger                                                                                                                                                |
| 395 |    273.598477 |    728.972370 | Carlos Cano-Barbacil                                                                                                                                         |
| 396 |    859.962402 |    490.091425 | Markus A. Grohme                                                                                                                                             |
| 397 |    862.427232 |    774.776922 | Elizabeth Parker                                                                                                                                             |
| 398 |    291.147829 |    160.408685 | Sarah Werning                                                                                                                                                |
| 399 |    356.529199 |    398.496490 | Jagged Fang Designs                                                                                                                                          |
| 400 |    207.699606 |    409.167517 | Ferran Sayol                                                                                                                                                 |
| 401 |    998.266600 |    455.810212 | Pearson Scott Foresman (vectorized by T. Michael Keesey)                                                                                                     |
| 402 |    867.515650 |    281.790648 | Sarah Werning                                                                                                                                                |
| 403 |     35.498406 |    192.969683 | Gareth Monger                                                                                                                                                |
| 404 |    471.215826 |    119.464412 | Scott Hartman                                                                                                                                                |
| 405 |    551.475492 |    481.820255 | Steven Traver                                                                                                                                                |
| 406 |    228.799810 |    578.574623 | E. R. Waite & H. M. Hale (vectorized by T. Michael Keesey)                                                                                                   |
| 407 |    128.911011 |    438.735187 | Cesar Julian                                                                                                                                                 |
| 408 |    872.791442 |    415.228813 | Gabriela Palomo-Munoz                                                                                                                                        |
| 409 |    664.861436 |    301.217792 | T. Michael Keesey                                                                                                                                            |
| 410 |   1008.210101 |     60.657998 | C. Camilo Julián-Caballero                                                                                                                                   |
| 411 |    952.499292 |    232.549084 | Gabriela Palomo-Munoz                                                                                                                                        |
| 412 |    146.681011 |    194.161620 | Gabriela Palomo-Munoz                                                                                                                                        |
| 413 |     15.978234 |    197.257096 | Roger Witter, vectorized by Zimices                                                                                                                          |
| 414 |    607.020257 |     46.362415 | Jagged Fang Designs                                                                                                                                          |
| 415 |    594.812396 |    484.369001 | Ferran Sayol                                                                                                                                                 |
| 416 |    971.739868 |      6.337089 | Gareth Monger                                                                                                                                                |
| 417 |    109.455901 |    589.028668 | Gareth Monger                                                                                                                                                |
| 418 |     32.252656 |    605.447407 | Margot Michaud                                                                                                                                               |
| 419 |    817.537608 |    684.991106 | Matt Crook                                                                                                                                                   |
| 420 |    956.340265 |    345.673456 | Anthony Caravaggi                                                                                                                                            |
| 421 |    610.909349 |     68.101622 | B. Duygu Özpolat                                                                                                                                             |
| 422 |    867.021385 |    356.323670 | Sarah Werning                                                                                                                                                |
| 423 |    312.306299 |    793.100261 | Margot Michaud                                                                                                                                               |
| 424 |    134.452395 |    691.393814 | Gareth Monger                                                                                                                                                |
| 425 |    236.901102 |    141.319583 | Tracy A. Heath                                                                                                                                               |
| 426 |    633.651286 |     82.430402 | L. Shyamal                                                                                                                                                   |
| 427 |    715.383563 |    561.017131 | Collin Gross                                                                                                                                                 |
| 428 |   1015.237776 |    652.345709 | Gareth Monger                                                                                                                                                |
| 429 |    282.163214 |    651.309699 | Scott Hartman                                                                                                                                                |
| 430 |    100.584894 |    465.300020 | Markus A. Grohme                                                                                                                                             |
| 431 |    991.280901 |    521.209959 | Marcos Pérez-Losada, Jens T. Høeg & Keith A. Crandall                                                                                                        |
| 432 |    446.316650 |    322.113529 | Gopal Murali                                                                                                                                                 |
| 433 |    265.958885 |    797.802696 | Margot Michaud                                                                                                                                               |
| 434 |    379.257369 |    751.863694 | Noah Schlottman, photo by Carlos Sánchez-Ortiz                                                                                                               |
| 435 |    535.602160 |    360.548931 | Abraão B. Leite                                                                                                                                              |
| 436 |    420.716875 |    455.356207 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                               |
| 437 |    726.018980 |    103.287505 | Ben Liebeskind                                                                                                                                               |
| 438 |    690.570386 |    790.641679 | M Kolmann                                                                                                                                                    |
| 439 |    454.025743 |    614.204059 | Allison Pease                                                                                                                                                |
| 440 |    390.461442 |     99.167945 | Tasman Dixon                                                                                                                                                 |
| 441 |   1014.531736 |    383.709775 | Joanna Wolfe                                                                                                                                                 |
| 442 |    831.592998 |    455.437745 | Neil Kelley                                                                                                                                                  |
| 443 |     16.789962 |     74.239609 | Gareth Monger                                                                                                                                                |
| 444 |    502.445192 |    753.831217 | Margot Michaud                                                                                                                                               |
| 445 |    875.512371 |    346.313269 | I. Geoffroy Saint-Hilaire (vectorized by T. Michael Keesey)                                                                                                  |
| 446 |     49.874638 |     37.644521 | Zimices, based in Mauricio Antón skeletal                                                                                                                    |
| 447 |    101.314596 |    277.959331 | T. Michael Keesey, from a photograph by Thea Boodhoo                                                                                                         |
| 448 |    549.298211 |    173.223309 | NA                                                                                                                                                           |
| 449 |    212.483747 |    382.891266 | xgirouxb                                                                                                                                                     |
| 450 |    419.055599 |    151.218384 | C. Camilo Julián-Caballero                                                                                                                                   |
| 451 |    971.447257 |    611.788488 | Ferran Sayol                                                                                                                                                 |
| 452 |    311.990585 |    269.442444 | Trond R. Oskars                                                                                                                                              |
| 453 |    732.878520 |    159.365668 | T. Michael Keesey                                                                                                                                            |
| 454 |    532.457593 |    561.503287 | Markus A. Grohme                                                                                                                                             |
| 455 |     73.061012 |    475.602357 | Nobu Tamura and T. Michael Keesey                                                                                                                            |
| 456 |    752.214398 |    432.042264 | Andy Wilson                                                                                                                                                  |
| 457 |    977.078170 |    545.011642 | Martin Kevil                                                                                                                                                 |
| 458 |    456.132451 |    221.955484 | Ben Liebeskind                                                                                                                                               |
| 459 |    192.051753 |    325.491080 | Campbell Fleming                                                                                                                                             |
| 460 |    390.243170 |    495.194707 | Sam Fraser-Smith (vectorized by T. Michael Keesey)                                                                                                           |
| 461 |    673.126335 |    484.907218 | Antonov (vectorized by T. Michael Keesey)                                                                                                                    |
| 462 |    324.008599 |     42.695985 | Jagged Fang Designs                                                                                                                                          |
| 463 |   1006.133526 |    681.998038 | Archaeodontosaurus (vectorized by T. Michael Keesey)                                                                                                         |
| 464 |    889.297766 |    278.074730 | Steven Traver                                                                                                                                                |
| 465 |    815.628299 |     53.478369 | Zimices                                                                                                                                                      |
| 466 |    503.358865 |    792.323243 | Warren H (photography), T. Michael Keesey (vectorization)                                                                                                    |
| 467 |    678.272818 |    134.787645 | Mason McNair                                                                                                                                                 |
| 468 |    677.446565 |    359.767901 | Jagged Fang Designs                                                                                                                                          |
| 469 |    217.027366 |    526.611369 | Gareth Monger                                                                                                                                                |
| 470 |    793.995549 |    620.155900 | Matthew E. Clapham                                                                                                                                           |
| 471 |    968.992362 |    228.277931 | Charles R. Knight, vectorized by Zimices                                                                                                                     |
| 472 |    178.860496 |    480.330214 | Jagged Fang Designs                                                                                                                                          |
| 473 |    265.873678 |    749.108374 | Julio Garza                                                                                                                                                  |
| 474 |    661.667958 |    683.337880 | Christoph Schomburg                                                                                                                                          |
| 475 |    681.301976 |    467.168604 | Roberto Díaz Sibaja                                                                                                                                          |
| 476 |    801.155944 |    102.519270 | Andy Wilson                                                                                                                                                  |
| 477 |    435.248589 |    611.875270 | Kailah Thorn & Mark Hutchinson                                                                                                                               |
| 478 |     32.976217 |    214.628619 | Zimices / Julián Bayona                                                                                                                                      |
| 479 |    859.215993 |    427.244828 | Kamil S. Jaron                                                                                                                                               |
| 480 |    936.467076 |    511.595563 | Birgit Lang                                                                                                                                                  |
| 481 |    215.903766 |     32.305545 | T. Michael Keesey (from a photograph by Frank Glaw, Jörn Köhler, Ted M. Townsend & Miguel Vences)                                                            |
| 482 |    859.986967 |     29.658439 | Lisa Byrne                                                                                                                                                   |
| 483 |    145.067378 |    113.042438 | Tracy A. Heath                                                                                                                                               |
| 484 |    759.719180 |    341.329754 | Carlos Cano-Barbacil                                                                                                                                         |
| 485 |    746.900076 |    497.665846 | Steven Traver                                                                                                                                                |
| 486 |     75.177137 |    393.006755 | Matt Martyniuk (modified by T. Michael Keesey)                                                                                                               |
| 487 |    743.326456 |    730.355204 | Beth Reinke                                                                                                                                                  |
| 488 |   1003.483578 |    181.607677 | Matt Crook                                                                                                                                                   |
| 489 |    453.070706 |    682.573829 | Gareth Monger                                                                                                                                                |
| 490 |    455.541209 |    362.957071 | Anthony Caravaggi                                                                                                                                            |
| 491 |    291.985146 |    788.221079 | Jagged Fang Designs                                                                                                                                          |
| 492 |     98.919727 |    590.013185 | Chris huh                                                                                                                                                    |
| 493 |    700.465788 |    416.929601 | C. Camilo Julián-Caballero                                                                                                                                   |
| 494 |    743.748799 |    404.916673 | Sharon Wegner-Larsen                                                                                                                                         |
| 495 |    337.214809 |    695.169963 | Ewald Rübsamen                                                                                                                                               |
| 496 |    513.969914 |     78.062278 | Andy Wilson                                                                                                                                                  |
| 497 |    907.990456 |     78.010966 | Andy Wilson                                                                                                                                                  |
| 498 |    443.028105 |    296.440411 | Markus A. Grohme                                                                                                                                             |
| 499 |    996.241912 |    465.749306 | White Wolf                                                                                                                                                   |
| 500 |    551.184300 |    422.347856 | FunkMonk (Michael B. H.)                                                                                                                                     |
| 501 |    117.270823 |    670.854365 | Christine Axon                                                                                                                                               |
| 502 |    593.687055 |    672.093333 | Gabriela Palomo-Munoz                                                                                                                                        |
| 503 |   1019.439798 |    693.323326 | Ferran Sayol                                                                                                                                                 |
| 504 |     21.108978 |    117.468060 | Zimices                                                                                                                                                      |
| 505 |    230.514852 |    327.109104 | Chris huh                                                                                                                                                    |
| 506 |    473.453182 |    686.141364 | Kai R. Caspar                                                                                                                                                |
| 507 |     26.398690 |    341.302078 | Iain Reid                                                                                                                                                    |
| 508 |     17.838186 |    357.298777 | Mathilde Cordellier                                                                                                                                          |
| 509 |     88.516763 |    727.315710 | Caleb M. Brown                                                                                                                                               |
| 510 |    652.334377 |    294.353048 | Ferran Sayol                                                                                                                                                 |
| 511 |      6.330753 |    491.576332 | T. Michael Keesey                                                                                                                                            |
| 512 |    162.929265 |    796.583205 | Smokeybjb                                                                                                                                                    |
| 513 |    486.093025 |    612.650652 | Maija Karala                                                                                                                                                 |
| 514 |     76.771632 |    240.753498 | Peileppe                                                                                                                                                     |
| 515 |     91.713651 |    630.192682 | Scott Hartman                                                                                                                                                |
| 516 |    265.725554 |    493.055729 | Ignacio Contreras                                                                                                                                            |
| 517 |    734.373147 |    414.158948 | Steven Traver                                                                                                                                                |
| 518 |   1000.274482 |    592.640238 | Chris huh                                                                                                                                                    |
| 519 |    232.830668 |    518.887980 | Steven Coombs                                                                                                                                                |
| 520 |    595.500213 |    418.068857 | Margot Michaud                                                                                                                                               |
| 521 |    351.932218 |     90.377009 | Beth Reinke                                                                                                                                                  |
| 522 |    336.102969 |    545.608623 | Javier Luque & Sarah Gerken                                                                                                                                  |
| 523 |    354.948039 |    529.314495 | Sam Droege (photography) and T. Michael Keesey (vectorization)                                                                                               |
| 524 |    568.813171 |     11.908571 | Felix Vaux                                                                                                                                                   |
| 525 |    102.485899 |    234.492461 | Zimices                                                                                                                                                      |
| 526 |    313.464895 |     28.314050 | Conty                                                                                                                                                        |
| 527 |    136.853073 |    300.870367 | Gareth Monger                                                                                                                                                |
| 528 |    461.575357 |    376.410009 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 529 |    758.707176 |    498.453665 | NA                                                                                                                                                           |
| 530 |    347.063081 |    665.022345 | Óscar San−Isidro (vectorized by T. Michael Keesey)                                                                                                           |
| 531 |    394.983777 |    334.988792 | Ferran Sayol                                                                                                                                                 |
| 532 |    798.880644 |    466.010087 | Zimices                                                                                                                                                      |
| 533 |    489.454850 |     88.177329 | Ingo Braasch                                                                                                                                                 |
| 534 |    345.213239 |    361.992567 | Jessica Rick                                                                                                                                                 |
| 535 |    209.579117 |    291.988818 | Gareth Monger                                                                                                                                                |
| 536 |    353.310590 |    455.652165 | Kai R. Caspar                                                                                                                                                |
| 537 |    449.863979 |    784.442266 | Gareth Monger                                                                                                                                                |
| 538 |    381.204368 |    515.943304 | Tasman Dixon                                                                                                                                                 |
| 539 |     45.649619 |     29.909691 | Francisco Gascó (modified by Michael P. Taylor)                                                                                                              |
| 540 |    753.732924 |    646.598527 | NA                                                                                                                                                           |
| 541 |    777.106496 |    139.723918 | Michael Scroggie                                                                                                                                             |
| 542 |    304.995866 |    732.609547 | Margot Michaud                                                                                                                                               |
| 543 |    591.168500 |    171.941605 | NA                                                                                                                                                           |
| 544 |    498.357594 |     82.530141 | Tasman Dixon                                                                                                                                                 |
| 545 |    409.939077 |    775.145145 | Thibaut Brunet                                                                                                                                               |
| 546 |    487.651164 |    248.476652 | NA                                                                                                                                                           |
| 547 |    849.621780 |    385.898086 | Kai R. Caspar                                                                                                                                                |
| 548 |    792.770939 |    138.561618 | Matt Crook                                                                                                                                                   |
| 549 |    695.896982 |    588.257245 | Gregor Bucher, Max Farnworth                                                                                                                                 |
| 550 |    897.457949 |    195.648562 | Sharon Wegner-Larsen                                                                                                                                         |
| 551 |    289.470574 |    663.418500 | Sidney Frederic Harmer, Arthur Everett Shipley (vectorized by Maxime Dahirel)                                                                                |
| 552 |    980.004861 |    383.218864 | Steven Traver                                                                                                                                                |
| 553 |    181.729462 |    460.375733 | Gabriela Palomo-Munoz                                                                                                                                        |
| 554 |     99.570654 |    154.174990 | Margot Michaud                                                                                                                                               |
| 555 |    867.833980 |    507.018004 | Armin Reindl                                                                                                                                                 |
| 556 |    801.980987 |    343.699976 | Christine Axon                                                                                                                                               |
| 557 |    680.164603 |    500.049876 | Sarah Werning                                                                                                                                                |
| 558 |    101.024959 |    367.466437 | Alexander Schmidt-Lebuhn                                                                                                                                     |
| 559 |    834.874700 |    387.842821 | Andy Wilson                                                                                                                                                  |
| 560 |    920.371072 |    642.275926 | Andy Wilson                                                                                                                                                  |
| 561 |    941.643308 |    220.303531 | S.Martini                                                                                                                                                    |
| 562 |     15.361291 |    640.667418 | Michelle Site                                                                                                                                                |
| 563 |    568.315553 |    138.398765 | Matt Crook                                                                                                                                                   |
| 564 |     22.646553 |    236.715843 | terngirl                                                                                                                                                     |
| 565 |    154.007301 |     16.143561 | Erika Schumacher                                                                                                                                             |
| 566 |    939.555497 |    247.230563 | Jagged Fang Designs                                                                                                                                          |
| 567 |     82.704672 |    464.312044 | Zimices                                                                                                                                                      |
| 568 |    182.850635 |    739.821484 | Zimices                                                                                                                                                      |
| 569 |    605.965142 |    602.671072 | Matt Crook                                                                                                                                                   |
| 570 |   1013.031470 |    629.802400 | Ingo Braasch                                                                                                                                                 |
| 571 |    381.188994 |    326.762061 | Scott Hartman                                                                                                                                                |
| 572 |    984.498361 |     38.749173 | Andy Wilson                                                                                                                                                  |
| 573 |    134.711923 |    446.473848 | T. Michael Keesey                                                                                                                                            |
| 574 |    928.150597 |    786.349210 | Steven Traver                                                                                                                                                |
| 575 |    196.458114 |    441.997482 | Emily Willoughby                                                                                                                                             |
| 576 |    270.340296 |      3.277499 | Zimices                                                                                                                                                      |
| 577 |    132.546363 |    324.467066 | Obsidian Soul (vectorized by T. Michael Keesey)                                                                                                              |
| 578 |    219.046085 |    492.957169 | Milton Tan                                                                                                                                                   |
| 579 |    685.495672 |    477.265688 | Jaime Headden, modified by T. Michael Keesey                                                                                                                 |
| 580 |    864.108714 |    369.885053 | Trond R. Oskars                                                                                                                                              |
| 581 |   1001.792076 |    360.021665 | Kai R. Caspar                                                                                                                                                |
| 582 |    461.536078 |    551.226064 | Zimices                                                                                                                                                      |
| 583 |    822.334465 |     23.708886 | Gabriela Palomo-Munoz                                                                                                                                        |
| 584 |    285.132844 |    230.483273 | Sharon Wegner-Larsen                                                                                                                                         |
| 585 |    516.655656 |    343.007904 | Smokeybjb, vectorized by Zimices                                                                                                                             |
| 586 |    483.034305 |    796.079592 | Steven Coombs                                                                                                                                                |
| 587 |    440.025563 |    203.778472 | NASA                                                                                                                                                         |
| 588 |    796.171430 |    432.389299 | Andy Wilson                                                                                                                                                  |
| 589 |    626.550279 |    562.005000 | Zachary Quigley                                                                                                                                              |
| 590 |    104.153446 |    428.203368 | Zimices                                                                                                                                                      |
| 591 |   1007.065782 |     45.377203 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 592 |    666.451099 |    787.820485 | T. Michael Keesey (photo by Bc999 \[Black crow\])                                                                                                            |
| 593 |   1002.173269 |    606.876703 | Smokeybjb, vectorized by Zimices                                                                                                                             |
| 594 |    861.733719 |    249.173721 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                             |
| 595 |    155.389106 |    727.933313 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 596 |    700.170581 |    273.273583 | Zimices                                                                                                                                                      |
| 597 |    281.467309 |    612.328148 | Kamil S. Jaron                                                                                                                                               |
| 598 |    492.554813 |    562.720834 | Dori <dori@merr.info> (source photo) and Nevit Dilmen                                                                                                        |
| 599 |    481.958886 |    387.949542 | Mo Hassan                                                                                                                                                    |
| 600 |     91.899214 |    111.081797 | Iain Reid                                                                                                                                                    |
| 601 |    819.418092 |    628.065467 | Jagged Fang Designs                                                                                                                                          |
| 602 |     21.556910 |    581.392845 | Francesca Belem Lopes Palmeira                                                                                                                               |
| 603 |    252.843572 |    738.594174 | Dmitry Bogdanov                                                                                                                                              |
| 604 |    697.019514 |    613.316737 | Margot Michaud                                                                                                                                               |
| 605 |    919.287012 |    206.476896 | Matt Crook                                                                                                                                                   |
| 606 |    613.996975 |    354.969189 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 607 |    809.533242 |    352.422913 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                           |
| 608 |     18.846993 |    651.826180 | Joanna Wolfe                                                                                                                                                 |
| 609 |    972.209759 |    577.890168 | Kanako Bessho-Uehara                                                                                                                                         |
| 610 |    461.124450 |    388.067212 | Dean Schnabel                                                                                                                                                |
| 611 |    439.284426 |    136.876437 | Chris huh                                                                                                                                                    |
| 612 |    213.925387 |    241.518181 | Andrés Sánchez                                                                                                                                               |
| 613 |    164.391071 |    790.225355 | \[unknown\]                                                                                                                                                  |
| 614 |      8.264672 |    366.543625 | Matt Wilkins                                                                                                                                                 |
| 615 |    334.279155 |    741.534765 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 616 |    769.584188 |     56.129432 | Matt Crook                                                                                                                                                   |
| 617 |    540.819655 |    642.957693 | Margot Michaud                                                                                                                                               |
| 618 |    524.843182 |    167.619152 | Zimices                                                                                                                                                      |
| 619 |    151.775346 |    768.873980 | Margot Michaud                                                                                                                                               |
| 620 |    366.137256 |    153.644498 | Matt Martyniuk                                                                                                                                               |
| 621 |    249.854476 |    630.408359 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 622 |   1009.620273 |    365.861708 | Gareth Monger                                                                                                                                                |
| 623 |    485.883112 |    765.466133 | Scott Hartman                                                                                                                                                |
| 624 |    727.935706 |    172.153041 | Mathieu Pélissié                                                                                                                                             |
| 625 |     77.130759 |    590.960527 | Oren Peles / vectorized by Yan Wong                                                                                                                          |
| 626 |     83.850868 |    216.505900 | Margot Michaud                                                                                                                                               |
| 627 |    551.970311 |    793.376021 | Zimices                                                                                                                                                      |
| 628 |    934.666334 |    260.436985 | T. Michael Keesey                                                                                                                                            |
| 629 |    732.294135 |    183.241081 | Beth Reinke                                                                                                                                                  |
| 630 |    932.303562 |    563.536557 | Scott Reid                                                                                                                                                   |
| 631 |    460.162652 |    575.396640 | Ignacio Contreras                                                                                                                                            |
| 632 |    136.680735 |    591.370874 | Margot Michaud                                                                                                                                               |
| 633 |    516.406777 |    434.151567 | Beth Reinke                                                                                                                                                  |
| 634 |    526.705757 |    182.315269 | NA                                                                                                                                                           |
| 635 |    330.349112 |     26.843783 | Margot Michaud                                                                                                                                               |
| 636 |    158.590448 |    449.393461 | Matt Martyniuk                                                                                                                                               |
| 637 |    396.509175 |     72.768479 | Tracy A. Heath                                                                                                                                               |
| 638 |    290.183119 |    191.008625 | Gabriela Palomo-Munoz                                                                                                                                        |
| 639 |    304.700332 |    680.767972 | Matt Martyniuk (vectorized by T. Michael Keesey)                                                                                                             |
| 640 |    208.120778 |    736.681538 | Renato Santos                                                                                                                                                |
| 641 |    584.723980 |    322.797898 | Mathilde Cordellier                                                                                                                                          |
| 642 |    989.207506 |    308.480653 | Matt Crook                                                                                                                                                   |
| 643 |    555.549043 |    354.290689 | Antonov (vectorized by T. Michael Keesey)                                                                                                                    |
| 644 |    162.662733 |    188.741526 | Jiekun He                                                                                                                                                    |
| 645 |    472.998106 |    626.045562 | Chris huh                                                                                                                                                    |
| 646 |    279.144724 |    625.839264 | Matt Crook                                                                                                                                                   |
| 647 |    391.343935 |    428.222229 | Ferran Sayol                                                                                                                                                 |
| 648 |    702.505697 |    641.878207 | T. Michael Keesey (after Kukalová)                                                                                                                           |
| 649 |    234.998346 |    264.555556 | T. Michael Keesey                                                                                                                                            |
| 650 |    626.839603 |     67.496968 | Gareth Monger                                                                                                                                                |
| 651 |    278.791342 |    788.595709 | Gareth Monger                                                                                                                                                |
| 652 |    537.806034 |    191.393927 | Mariana Ruiz Villarreal                                                                                                                                      |
| 653 |    556.030644 |     74.828270 | Ferran Sayol                                                                                                                                                 |
| 654 |    766.831315 |     90.840266 | Kent Elson Sorgon                                                                                                                                            |
| 655 |    233.355250 |    412.529364 | Margot Michaud                                                                                                                                               |
| 656 |    650.407882 |     62.861384 | Jaime Headden                                                                                                                                                |
| 657 |    585.608845 |    207.777220 | Zimices                                                                                                                                                      |
| 658 |    663.690101 |    552.957987 | Kent Elson Sorgon                                                                                                                                            |
| 659 |    352.867010 |    382.476961 | Milton Tan                                                                                                                                                   |
| 660 |    287.294076 |      5.318317 | Chris huh                                                                                                                                                    |
| 661 |    334.907807 |    559.418587 | Zimices                                                                                                                                                      |
| 662 |     41.000689 |    748.270983 | Yan Wong from drawing in The Century Dictionary (1911)                                                                                                       |
| 663 |    411.872005 |    639.905592 | Ferran Sayol                                                                                                                                                 |
| 664 |    569.875854 |    183.307213 | T. Michael Keesey                                                                                                                                            |
| 665 |    675.492603 |      8.531664 | Tauana J. Cunha                                                                                                                                              |
| 666 |    744.380127 |    580.178319 | Chris A. Hamilton                                                                                                                                            |
| 667 |    955.703716 |    290.951503 | Harold N Eyster                                                                                                                                              |
| 668 |    842.197691 |    517.238026 | Yan Wong                                                                                                                                                     |
| 669 |    762.313087 |    729.540346 | Geoff Shaw                                                                                                                                                   |
| 670 |   1013.406907 |    564.634589 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 671 |     58.681426 |    359.373222 | Gabriela Palomo-Munoz                                                                                                                                        |
| 672 |    164.033953 |    200.592602 | Jimmy Bernot                                                                                                                                                 |
| 673 |    455.086000 |     28.658508 | Markus A. Grohme                                                                                                                                             |
| 674 |    311.117851 |    103.914317 | Steven Traver                                                                                                                                                |
| 675 |    267.520857 |    330.628659 | Michelle Site                                                                                                                                                |
| 676 |    296.139691 |    212.736896 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 677 |    253.654773 |      8.312759 | Tyler Greenfield and Scott Hartman                                                                                                                           |
| 678 |    377.346768 |    122.986516 | NA                                                                                                                                                           |
| 679 |    599.355950 |    702.380444 | Markus A. Grohme                                                                                                                                             |
| 680 |    121.360588 |    461.004744 | Caleb Brown                                                                                                                                                  |
| 681 |    515.441942 |    390.658260 | Margot Michaud                                                                                                                                               |
| 682 |   1004.338468 |    319.725056 | Michelle Site                                                                                                                                                |
| 683 |    726.920699 |     77.926263 | Matt Crook                                                                                                                                                   |
| 684 |    376.880444 |    502.123207 | Mathew Stewart                                                                                                                                               |
| 685 |    110.349916 |    444.758935 | Gabriela Palomo-Munoz                                                                                                                                        |
| 686 |    964.567752 |    531.584851 | C. Camilo Julián-Caballero                                                                                                                                   |
| 687 |    618.113321 |    387.421138 | Ferran Sayol                                                                                                                                                 |
| 688 |    173.205402 |     65.750808 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 689 |    401.056643 |    572.043641 | NA                                                                                                                                                           |
| 690 |    910.208276 |    438.662706 | T. Michael Keesey (from a mount by Allis Markham)                                                                                                            |
| 691 |    336.799015 |    273.586851 | NA                                                                                                                                                           |
| 692 |    656.090153 |    748.784894 | Zimices                                                                                                                                                      |
| 693 |    768.325971 |    351.709155 | Didier Descouens (vectorized by T. Michael Keesey)                                                                                                           |
| 694 |    664.747908 |    161.700493 | Mike Hanson                                                                                                                                                  |
| 695 |     26.073932 |    302.854744 | Robbie N. Cada (modified by T. Michael Keesey)                                                                                                               |
| 696 |    789.999908 |     61.790629 | Sarah Werning                                                                                                                                                |
| 697 |    228.945377 |    534.304765 | Matt Crook                                                                                                                                                   |
| 698 |    185.988666 |    682.377266 | Margot Michaud                                                                                                                                               |
| 699 |    640.804830 |    720.901985 | Robert Gay                                                                                                                                                   |
| 700 |    973.307270 |    297.065017 | Gareth Monger                                                                                                                                                |
| 701 |    709.191448 |    499.993847 | Tasman Dixon                                                                                                                                                 |
| 702 |    200.059787 |      8.578629 | Tim H. Heupink, Leon Huynen, and David M. Lambert (vectorized by T. Michael Keesey)                                                                          |
| 703 |     55.994586 |     71.468649 | Gabriela Palomo-Munoz                                                                                                                                        |
| 704 |    836.499252 |    684.985974 | Maija Karala                                                                                                                                                 |
| 705 |    929.525199 |    243.814079 | Diana Pomeroy                                                                                                                                                |
| 706 |    199.556799 |    552.660039 | Ferran Sayol                                                                                                                                                 |
| 707 |    986.260230 |    656.704167 | Ignacio Contreras                                                                                                                                            |
| 708 |    536.853080 |    458.348447 | Matt Crook                                                                                                                                                   |
| 709 |    680.339210 |    732.437461 | Steven Traver                                                                                                                                                |
| 710 |    180.871139 |    329.454382 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 711 |    821.753041 |     10.741610 | Maxime Dahirel                                                                                                                                               |
| 712 |    803.995671 |    224.735764 | Margot Michaud                                                                                                                                               |
| 713 |    891.715609 |    775.163585 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 714 |    248.726345 |    147.908398 | Gareth Monger                                                                                                                                                |
| 715 |    315.669488 |    212.663669 | Margot Michaud                                                                                                                                               |
| 716 |    740.701579 |    102.071766 | Jiekun He                                                                                                                                                    |
| 717 |    177.385527 |    110.094855 | Gareth Monger                                                                                                                                                |
| 718 |    124.184751 |    106.886033 | Jagged Fang Designs                                                                                                                                          |
| 719 |    655.000275 |     29.329983 | Matt Martyniuk                                                                                                                                               |
| 720 |    928.570180 |    310.946775 | Michele M Tobias                                                                                                                                             |
| 721 |    987.828904 |    713.198720 | Iain Reid                                                                                                                                                    |
| 722 |    692.290070 |    247.076642 | Ferran Sayol                                                                                                                                                 |
| 723 |     11.220923 |    587.380261 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 724 |    916.167637 |    602.814197 | Michelle Site                                                                                                                                                |
| 725 |     82.265774 |    786.962652 | NOAA Great Lakes Environmental Research Laboratory (illustration) and Timothy J. Bartley (silhouette)                                                        |
| 726 |    766.369875 |    719.473506 | Markus A. Grohme                                                                                                                                             |
| 727 |     40.338065 |    356.295895 | Anthony Caravaggi                                                                                                                                            |
| 728 |     13.850111 |    296.810367 | Xavier Giroux-Bougard                                                                                                                                        |
| 729 |     53.159887 |    376.966188 | U.S. National Park Service (vectorized by William Gearty)                                                                                                    |
| 730 |    146.143635 |    673.982336 | Gareth Monger                                                                                                                                                |
| 731 |    859.194239 |    458.754247 | Steven Traver                                                                                                                                                |
| 732 |    551.101291 |    135.345235 | Ferran Sayol                                                                                                                                                 |
| 733 |    118.686275 |    145.246609 | Gareth Monger                                                                                                                                                |
| 734 |    995.094648 |    430.635316 | Birgit Lang                                                                                                                                                  |
| 735 |    526.976422 |    742.126714 | Henry Fairfield Osborn, vectorized by Zimices                                                                                                                |
| 736 |    996.411331 |     51.100280 | Gareth Monger                                                                                                                                                |
| 737 |    908.821562 |    250.642756 | Mathieu Basille                                                                                                                                              |
| 738 |    955.917878 |    245.691762 | T. Michael Keesey                                                                                                                                            |
| 739 |     56.322528 |     45.525750 | Melissa Ingala                                                                                                                                               |
| 740 |    339.819994 |     44.331383 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 741 |    239.341106 |      9.202342 | Matthew E. Clapham                                                                                                                                           |
| 742 |     33.065799 |    177.818904 | Gabriela Palomo-Munoz                                                                                                                                        |
| 743 |    776.785610 |    226.287904 | Matt Crook                                                                                                                                                   |
| 744 |    324.539075 |    689.662690 | nicubunu                                                                                                                                                     |
| 745 |    206.746160 |    574.298908 | Margot Michaud                                                                                                                                               |
| 746 |    311.434538 |    765.921482 | Matt Crook                                                                                                                                                   |
| 747 |    849.392696 |    580.501531 | Robert Bruce Horsfall (vectorized by William Gearty)                                                                                                         |
| 748 |    752.467421 |    708.518471 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |
| 749 |    228.342869 |     22.068002 | James R. Spotila and Ray Chatterji                                                                                                                           |
| 750 |     10.264945 |    514.100719 | Matt Wilkins (photo by Patrick Kavanagh)                                                                                                                     |
| 751 |    259.665128 |    172.338843 | Ferran Sayol                                                                                                                                                 |
| 752 |    752.700693 |    413.890337 | L. Shyamal                                                                                                                                                   |
| 753 |    798.923474 |    640.586348 | M. Antonio Todaro, Tobias Kånneby, Matteo Dal Zotto, and Ulf Jondelius (vectorized by T. Michael Keesey)                                                     |
| 754 |    240.546497 |    170.110822 | Ferran Sayol                                                                                                                                                 |
| 755 |    586.897341 |     15.925675 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 756 |    689.590685 |    761.339745 | Emily Willoughby                                                                                                                                             |
| 757 |    954.055949 |    536.047567 | NA                                                                                                                                                           |
| 758 |    234.639905 |    503.900415 | Ferran Sayol                                                                                                                                                 |
| 759 |    378.045776 |    643.088186 | Zimices                                                                                                                                                      |
| 760 |    935.484693 |    326.754451 | Tracy A. Heath                                                                                                                                               |
| 761 |     30.534806 |    789.489561 | Maxime Dahirel                                                                                                                                               |
| 762 |    177.714846 |    695.176680 | NA                                                                                                                                                           |
| 763 |    990.640789 |    477.529517 | Gareth Monger                                                                                                                                                |
| 764 |    291.831012 |    382.086405 | Air Kebir NRG                                                                                                                                                |
| 765 |    140.735340 |    779.476481 | NA                                                                                                                                                           |
| 766 |    707.039049 |     63.882284 | Tauana J. Cunha                                                                                                                                              |
| 767 |    291.220975 |    577.188825 | Ferran Sayol                                                                                                                                                 |
| 768 |    279.615464 |    171.508617 | Jessica Anne Miller                                                                                                                                          |
| 769 |    508.886010 |    560.765826 | Zimices                                                                                                                                                      |
| 770 |   1011.873632 |    763.880087 | Tyler Greenfield                                                                                                                                             |
| 771 |    445.197899 |    556.557939 | Zimices                                                                                                                                                      |
| 772 |    678.824064 |    572.305836 | Jagged Fang Designs                                                                                                                                          |
| 773 |     10.991233 |    403.706950 | Chris huh                                                                                                                                                    |
| 774 |    597.217216 |    352.533660 | Matt Wilkins                                                                                                                                                 |
| 775 |     64.030514 |    734.528180 | Tasman Dixon                                                                                                                                                 |
| 776 |    821.771816 |    359.353951 | Scott Hartman                                                                                                                                                |
| 777 |    889.826381 |    155.272599 | Steven Coombs                                                                                                                                                |
| 778 |    525.724910 |    373.397898 | Margot Michaud                                                                                                                                               |
| 779 |     32.002350 |    487.486358 | Christine Axon                                                                                                                                               |
| 780 |    483.936117 |    675.314621 | Servien (vectorized by T. Michael Keesey)                                                                                                                    |
| 781 |    444.831457 |     36.317199 | M Kolmann                                                                                                                                                    |
| 782 |    580.288067 |    405.103060 | Jose Carlos Arenas-Monroy                                                                                                                                    |
| 783 |   1016.351166 |     82.177066 | Aline M. Ghilardi                                                                                                                                            |
| 784 |    651.014177 |    239.117131 | Tasman Dixon                                                                                                                                                 |
| 785 |    291.104897 |    234.675367 | Harold N Eyster                                                                                                                                              |
| 786 |    311.826896 |    289.253226 | Yan Wong                                                                                                                                                     |
| 787 |    432.018397 |    267.220317 | C. Camilo Julián-Caballero                                                                                                                                   |
| 788 |    749.776505 |     21.159115 | L. Shyamal                                                                                                                                                   |
| 789 |    205.590793 |    791.351438 | Charles Doolittle Walcott (vectorized by T. Michael Keesey)                                                                                                  |
| 790 |    298.562525 |    133.023130 | Noah Schlottman, photo by David J Patterson                                                                                                                  |
| 791 |     61.793883 |     90.653664 | Nina Skinner                                                                                                                                                 |
| 792 |    463.530793 |    646.244447 | Dean Schnabel                                                                                                                                                |
| 793 |    982.433114 |    574.212334 | Steven Traver                                                                                                                                                |
| 794 |    358.803696 |    479.078023 | Gabriela Palomo-Munoz                                                                                                                                        |
| 795 |    700.003822 |    173.314827 | Gareth Monger                                                                                                                                                |
| 796 |    606.594749 |    649.298784 | Michelle Site                                                                                                                                                |
| 797 |    285.298193 |    458.812623 | Konsta Happonen, from a CC-BY-NC image by sokolkov2002 on iNaturalist                                                                                        |
| 798 |    319.660912 |    311.861650 | L. Shyamal                                                                                                                                                   |
| 799 |    551.871816 |    603.524444 | Martin Kevil                                                                                                                                                 |
| 800 |    225.507066 |    450.650856 | Stanton F. Fink (vectorized by T. Michael Keesey)                                                                                                            |
| 801 |    237.981881 |    115.979426 | Cesar Julian                                                                                                                                                 |
| 802 |   1007.518555 |    397.811127 | Matt Crook                                                                                                                                                   |
| 803 |    105.821509 |     54.358895 | Erika Schumacher                                                                                                                                             |
| 804 |    643.686168 |    271.354390 | Tyler Greenfield and Dean Schnabel                                                                                                                           |
| 805 |    388.345494 |    636.385455 | Gabriela Palomo-Munoz                                                                                                                                        |
| 806 |    192.617077 |    229.900265 | Zimices                                                                                                                                                      |
| 807 |    502.169488 |    726.629165 | Jagged Fang Designs                                                                                                                                          |
| 808 |    686.841553 |     15.540815 | Brad McFeeters (vectorized by T. Michael Keesey)                                                                                                             |
| 809 |    152.063612 |    689.473452 | Kanchi Nanjo                                                                                                                                                 |
| 810 |    468.299735 |    137.158440 | Matus Valach                                                                                                                                                 |
| 811 |    770.295923 |    563.076893 | NA                                                                                                                                                           |
| 812 |    533.316424 |    444.223478 | Scott Reid                                                                                                                                                   |
| 813 |    412.393475 |    136.143728 | Joanna Wolfe                                                                                                                                                 |
| 814 |    866.664894 |    214.955575 | Joanna Wolfe                                                                                                                                                 |
| 815 |    482.124901 |    103.004810 | Chris Hay                                                                                                                                                    |
| 816 |     47.269455 |    483.340502 | CNZdenek                                                                                                                                                     |
| 817 |    570.806297 |    126.966837 | Jagged Fang Designs                                                                                                                                          |
| 818 |    650.589660 |     84.574249 | Jiekun He                                                                                                                                                    |
| 819 |    688.759484 |    706.156459 | Nobu Tamura                                                                                                                                                  |
| 820 |    641.357904 |    650.076875 | NA                                                                                                                                                           |
| 821 |    433.250334 |    305.509006 | Zimices                                                                                                                                                      |
| 822 |    975.527211 |     48.720285 | Matt Crook                                                                                                                                                   |
| 823 |    590.869192 |    791.953051 | Matt Crook                                                                                                                                                   |
| 824 |    926.894961 |    451.816728 | T. Michael Keesey                                                                                                                                            |
| 825 |    277.136812 |    104.862912 | FJDegrange                                                                                                                                                   |
| 826 |    259.988298 |     98.778434 | Dmitry Bogdanov                                                                                                                                              |
| 827 |    826.825262 |    342.381417 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 828 |     17.886006 |    277.388421 | Iain Reid                                                                                                                                                    |
| 829 |    849.015869 |    254.741048 | Sarah Werning                                                                                                                                                |
| 830 |    432.068909 |    385.572071 | Ferran Sayol                                                                                                                                                 |
| 831 |    198.295270 |    131.256553 | Noah Schlottman, photo by Casey Dunn                                                                                                                         |
| 832 |    591.760935 |    656.672618 | Gabriela Palomo-Munoz                                                                                                                                        |
| 833 |    256.459994 |    744.005277 | NA                                                                                                                                                           |
| 834 |    615.139762 |    396.891839 | Raven Amos                                                                                                                                                   |
| 835 |    698.920886 |    485.963955 | Adam Stuart Smith (vectorized by T. Michael Keesey)                                                                                                          |
| 836 |    885.674089 |    113.909829 | Tasman Dixon                                                                                                                                                 |
| 837 |    398.655797 |    134.173278 | Noah Schlottman                                                                                                                                              |
| 838 |    368.790171 |    687.287870 | Steven Traver                                                                                                                                                |
| 839 |     43.202714 |    609.976281 | Apokryltaros (vectorized by T. Michael Keesey)                                                                                                               |
| 840 |   1010.438220 |    500.271672 | Andrew A. Farke                                                                                                                                              |
| 841 |    998.492843 |    545.165227 | Zimices                                                                                                                                                      |
| 842 |    895.570832 |    353.468205 | Markus A. Grohme                                                                                                                                             |
| 843 |    574.860527 |    712.564894 | Gabriela Palomo-Munoz                                                                                                                                        |
| 844 |    906.390972 |    288.830391 | Conty (vectorized by T. Michael Keesey)                                                                                                                      |
| 845 |    398.645812 |    231.299809 | Gareth Monger                                                                                                                                                |
| 846 |    632.427880 |    758.234641 | NA                                                                                                                                                           |
| 847 |     82.827635 |    646.153490 | Yan Wong                                                                                                                                                     |
| 848 |    266.762493 |    314.801290 | Ferran Sayol                                                                                                                                                 |
| 849 |    801.408354 |    646.481413 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 850 |    776.119844 |    598.562549 | Margot Michaud                                                                                                                                               |
| 851 |    876.171967 |    383.846956 | Jagged Fang Designs                                                                                                                                          |
| 852 |    513.303372 |    356.252243 | Ieuan Jones                                                                                                                                                  |
| 853 |    722.625507 |    266.534753 | Andy Wilson                                                                                                                                                  |
| 854 |    543.511730 |    693.294200 | Zimices                                                                                                                                                      |
| 855 |    660.372699 |    722.334868 | Chris huh                                                                                                                                                    |
| 856 |    542.654160 |    157.427165 | \[unknown\]                                                                                                                                                  |
| 857 |    806.197500 |     80.111162 | Jagged Fang Designs                                                                                                                                          |
| 858 |    698.892808 |    678.711750 | Ghedoghedo (vectorized by T. Michael Keesey)                                                                                                                 |
| 859 |    948.222115 |    141.085883 | Gabriela Palomo-Munoz                                                                                                                                        |
| 860 |     11.214826 |    715.244293 | Zimices                                                                                                                                                      |
| 861 |     44.135234 |    729.609757 | Andy Wilson                                                                                                                                                  |
| 862 |    627.755547 |     56.855648 | Roderic Page and Lois Page                                                                                                                                   |
| 863 |    403.923720 |    503.308378 | Zimices                                                                                                                                                      |
| 864 |    750.224318 |    478.515517 | Thibaut Brunet                                                                                                                                               |
| 865 |    561.688806 |    771.662802 | Carlos Cano-Barbacil                                                                                                                                         |
| 866 |    383.737262 |     58.455940 | Melissa Broussard                                                                                                                                            |
| 867 |    475.065625 |    519.790311 | Margot Michaud                                                                                                                                               |
| 868 |      9.129018 |    282.208987 | Gareth Monger                                                                                                                                                |
| 869 |    389.876479 |      7.539536 | Nobu Tamura (vectorized by T. Michael Keesey)                                                                                                                |
| 870 |    893.470961 |     26.470004 | Kai R. Caspar                                                                                                                                                |
| 871 |    660.060517 |    522.372096 | Smokeybjb                                                                                                                                                    |
| 872 |     33.738783 |    639.260266 | Gabriela Palomo-Munoz                                                                                                                                        |
| 873 |    481.374002 |    576.670121 | Alex Slavenko                                                                                                                                                |
| 874 |    985.078091 |    585.498971 | Tyler Greenfield                                                                                                                                             |
| 875 |    988.230288 |    694.699770 | Kamil S. Jaron                                                                                                                                               |
| 876 |    584.891498 |    260.854234 | Mathilde Cordellier                                                                                                                                          |
| 877 |    156.915800 |    321.337899 | Margot Michaud                                                                                                                                               |
| 878 |    632.420498 |    625.195109 | Crystal Maier                                                                                                                                                |
| 879 |    409.474825 |    256.488300 | Matt Crook                                                                                                                                                   |
| 880 |    943.695771 |    310.810081 | T. Michael Keesey (vectorization); Yves Bousquet (photography)                                                                                               |
| 881 |    200.075318 |    748.621739 | Margot Michaud                                                                                                                                               |
| 882 |    786.727248 |    664.908042 | Andy Wilson                                                                                                                                                  |
| 883 |    164.878082 |     36.561038 | Tasman Dixon                                                                                                                                                 |
| 884 |    849.229722 |    620.565545 | U.S. National Park Service (vectorized by William Gearty)                                                                                                    |
| 885 |    568.399177 |    780.120861 | Margot Michaud                                                                                                                                               |
| 886 |     47.378960 |    370.568591 | Haplochromis (vectorized by T. Michael Keesey)                                                                                                               |
| 887 |    336.530015 |    681.983638 | Matus Valach                                                                                                                                                 |
| 888 |    985.368301 |    339.399169 | A. R. McCulloch (vectorized by T. Michael Keesey)                                                                                                            |
| 889 |    682.644719 |    314.659935 | Jagged Fang Designs                                                                                                                                          |
| 890 |    246.422663 |    513.125010 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 891 |      4.131569 |    236.740852 | Gareth Monger                                                                                                                                                |
| 892 |    206.004482 |    317.456198 | Zimices                                                                                                                                                      |
| 893 |    797.759600 |      7.930797 | Michelle Site                                                                                                                                                |
| 894 |      7.674386 |    347.030278 | Margot Michaud                                                                                                                                               |
| 895 |    885.316296 |    297.664487 | Zimices                                                                                                                                                      |
| 896 |    113.173058 |    779.258198 | Scott Hartman                                                                                                                                                |
| 897 |    986.606627 |    350.391352 | Zimices                                                                                                                                                      |
| 898 |    663.663827 |    250.486592 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |
| 899 |    571.901378 |    448.799104 | Matt Crook                                                                                                                                                   |
| 900 |    870.160443 |     24.177943 | Markus A. Grohme                                                                                                                                             |
| 901 |    781.222553 |    152.576931 | Ewald Rübsamen                                                                                                                                               |
| 902 |    909.342233 |    759.000288 | Rene Martin                                                                                                                                                  |
| 903 |    363.548953 |    672.265182 | Xavier Giroux-Bougard                                                                                                                                        |
| 904 |    969.712202 |    553.345410 | Gareth Monger                                                                                                                                                |
| 905 |   1003.880075 |     26.121426 | Michael Scroggie                                                                                                                                             |
| 906 |    449.809561 |      6.124086 | T. Michael Keesey                                                                                                                                            |
| 907 |     10.126234 |    532.674047 | Anthony Caravaggi                                                                                                                                            |
| 908 |    197.740789 |    137.837488 | Frederick William Frohawk (vectorized by T. Michael Keesey)                                                                                                  |
| 909 |    430.941665 |    258.295504 | Dean Schnabel                                                                                                                                                |
| 910 |    187.810800 |     39.743116 | Jaime Headden                                                                                                                                                |
| 911 |    525.438896 |    784.561471 | Pedro de Siracusa                                                                                                                                            |
| 912 |    766.423828 |    571.976822 | Tauana J. Cunha                                                                                                                                              |
| 913 |    985.596030 |     79.940359 | xgirouxb                                                                                                                                                     |
| 914 |    416.781064 |    474.731357 | Jessica Rick                                                                                                                                                 |
| 915 |    779.407720 |     13.331465 | Hugo Gruson                                                                                                                                                  |
| 916 |    442.160712 |    589.620562 | Sarah Werning                                                                                                                                                |
| 917 |    503.192517 |     31.470297 | Dmitry Bogdanov (vectorized by T. Michael Keesey)                                                                                                            |
| 918 |    786.042969 |    541.220664 | Hans Hillewaert (vectorized by T. Michael Keesey)                                                                                                            |

    #> Your tweet has been posted!
